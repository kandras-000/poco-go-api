package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	sqlcdb "poco/internal/db/sqlc"
)

type UserHandler struct {
	queries *sqlcdb.Queries
}

func NewUserHandler(queries *sqlcdb.Queries) *UserHandler {
	return &UserHandler{queries: queries}
}

func (h *UserHandler) ListUsers(c *gin.Context) {
	users, err := h.queries.ListUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list users"})
		return
	}
	if users == nil {
		users = []sqlcdb.ListUsersRow{}
	}
	c.JSON(http.StatusOK, users)
}
