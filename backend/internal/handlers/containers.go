package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	sqlcdb "poco/internal/db/sqlc"
)

type ContainerHandler struct {
	queries *sqlcdb.Queries
}

func NewContainerHandler(queries *sqlcdb.Queries) *ContainerHandler {
	return &ContainerHandler{queries: queries}
}

type CreateContainerRequest struct {
	Name string `json:"name" binding:"required,min=1,max=255"`
}

func (h *ContainerHandler) Create(c *gin.Context) {
	userID := c.GetString("userID")

	var req CreateContainerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	container, err := h.queries.CreateContainer(c.Request.Context(), sqlcdb.CreateContainerParams{
		UserID: userUUID,
		Name:   req.Name,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create container"})
		return
	}

	c.JSON(http.StatusCreated, container)
}

func (h *ContainerHandler) List(c *gin.Context) {
	userID := c.GetString("userID")

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	containers, err := h.queries.ListContainersByUser(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch containers"})
		return
	}

	if containers == nil {
		containers = []sqlcdb.EvidenceContainer{}
	}

	c.JSON(http.StatusOK, containers)
}

func (h *ContainerHandler) Delete(c *gin.Context) {
	userID := c.GetString("userID")
	containerID := c.Param("id")

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	containerUUID, err := uuid.Parse(containerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid container id"})
		return
	}

	container, err := h.queries.GetContainerByID(c.Request.Context(), containerUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "container not found"})
		return
	}

	if container.UserID != userUUID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.queries.DeleteContainer(c.Request.Context(), sqlcdb.DeleteContainerParams{
		ID:     containerUUID,
		UserID: userUUID,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete container"})
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *ContainerHandler) ListEvidence(c *gin.Context) {
	userID := c.GetString("userID")
	containerID := c.Param("id")

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	containerUUID, err := uuid.Parse(containerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid container id"})
		return
	}

	container, err := h.queries.GetContainerByID(c.Request.Context(), containerUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "container not found"})
		return
	}
	if container.UserID != userUUID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	items, err := h.queries.ListEvidenceByContainer(c.Request.Context(), pgtype.UUID{
		Bytes: [16]byte(containerUUID),
		Valid: true,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch evidence"})
		return
	}

	if items == nil {
		items = []sqlcdb.Evidence{}
	}

	c.JSON(http.StatusOK, items)
}
