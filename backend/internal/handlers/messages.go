package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	sqlcdb "poco/internal/db/sqlc"
	"poco/internal/ws"
)

// MessageResponse is the JSON shape for messages sent to clients.
type MessageResponse struct {
	ID             uuid.UUID `json:"id"`
	SenderID       uuid.UUID `json:"sender_id"`
	SenderUsername string    `json:"sender_username"`
	RecipientID    uuid.UUID `json:"recipient_id"`
	Content        string    `json:"content"`
	Delivered      bool      `json:"delivered"`
	CreatedAt      time.Time `json:"created_at"`
}

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

	resp := MessageResponse{
		ID:             msg.ID,
		SenderID:       msg.SenderID,
		SenderUsername: senderUsername,
		RecipientID:    msg.RecipientID,
		Content:        msg.Content,
		Delivered:      msg.Delivered,
		CreatedAt:      msg.CreatedAt,
	}

	if online {
		payload, _ := json.Marshal(ws.WSMessage{Type: "message", Data: resp})
		h.hub.SendToUser(req.RecipientID, payload)
	}

	c.JSON(http.StatusCreated, resp)
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

	result := make([]MessageResponse, 0, len(msgs))
	for _, m := range msgs {
		result = append(result, MessageResponse{
			ID:             m.ID,
			SenderID:       m.SenderID,
			SenderUsername: m.SenderUsername,
			RecipientID:    m.RecipientID,
			Content:        m.Content,
			Delivered:      m.Delivered,
			CreatedAt:      m.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, result)
}
