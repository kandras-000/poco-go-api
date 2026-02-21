package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"poco/internal/auth"
	sqlcdb "poco/internal/db/sqlc"
	"poco/internal/ws"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins in development
	},
}

type WSHandler struct {
	hub       *ws.Hub
	queries   *sqlcdb.Queries
	jwtSecret string
}

func NewWSHandler(hub *ws.Hub, queries *sqlcdb.Queries, jwtSecret string) *WSHandler {
	return &WSHandler{hub: hub, queries: queries, jwtSecret: jwtSecret}
}

func (h *WSHandler) HandleWS(c *gin.Context) {
	tokenStr := c.Query("token")
	if tokenStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "missing token query param"})
		return
	}

	claims, err := auth.ValidateToken(tokenStr, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("ws upgrade error: %v", err)
		return
	}

	client := ws.NewClient(h.hub, claims.UserID, conn)
	h.hub.Register(client)

	go h.deliverPending(client, claims.UserID)
	go client.WritePump()
	go client.ReadPump()
}

func (h *WSHandler) deliverPending(client *ws.Client, userIDStr string) {
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return
	}

	msgs, err := h.queries.GetUndeliveredMessages(context.Background(), userID)
	if err != nil {
		log.Printf("failed to fetch undelivered messages for %s: %v", userIDStr, err)
		return
	}

	for _, msg := range msgs {
		payload, _ := json.Marshal(ws.WSMessage{Type: "message", Data: msg})
		client.Send(payload)
		if err := h.queries.MarkMessageDelivered(context.Background(), msg.ID); err != nil {
			log.Printf("failed to mark message %s as delivered: %v", msg.ID, err)
		}
	}
}
