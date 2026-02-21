package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	sqlcdb "poco/internal/db/sqlc"
	"poco/internal/ws"
)

type MessageHandler struct {
	queries *sqlcdb.Queries
	hub     *ws.Hub
}

func NewMessageHandler(queries *sqlcdb.Queries, hub *ws.Hub) *MessageHandler {
	return &MessageHandler{queries: queries, hub: hub}
}

type SendMessageRequest struct {
	RecipientID string `json:"recipient_id" binding:"required"`
	Content     string `json:"content"      binding:"required,min=1"`
}

func (h *MessageHandler) SendMessage(c *gin.Context) {
	senderIDStr := c.GetString("userID")
	senderUsername := c.GetString("username")
	senderID, err := uuid.Parse(senderIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid sender ID"})
		return
	}

	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	recipientID, err := uuid.Parse(req.RecipientID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid recipient ID"})
		return
	}

	online := h.hub.IsOnline(req.RecipientID)

	msg, err := h.queries.CreateMessage(c.Request.Context(), sqlcdb.CreateMessageParams{
		SenderID:    senderID,
		RecipientID: recipientID,
		Content:     req.Content,
		Delivered:   online,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create message"})
		return
	}

	// Attach sender_username (from JWT — no extra DB query needed)
	msgWithSender := sqlcdb.MessageWithSender{
		ID:             msg.ID,
		SenderID:       msg.SenderID,
		RecipientID:    msg.RecipientID,
		Content:        msg.Content,
		Delivered:      msg.Delivered,
		CreatedAt:      msg.CreatedAt,
		SenderUsername: senderUsername,
	}

	if online {
		payload, _ := json.Marshal(ws.WSMessage{Type: "message", Data: msgWithSender})
		h.hub.SendToUser(req.RecipientID, payload)
	}

	c.JSON(http.StatusCreated, msgWithSender)
}

func (h *MessageHandler) GetMessages(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user ID"})
		return
	}

	otherIDStr := c.Param("userId")
	otherID, err := uuid.Parse(otherIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user ID param"})
		return
	}

	msgs, err := h.queries.GetMessagesBetweenUsers(c.Request.Context(), sqlcdb.GetMessagesBetweenUsersParams{
		SenderID:    userID,
		RecipientID: otherID,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get messages"})
		return
	}
	if msgs == nil {
		msgs = []sqlcdb.MessageWithSender{}
	}
	c.JSON(http.StatusOK, msgs)
}
