package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	sqlcdb "poco/internal/db/sqlc"
)

var allowedMIMEPrefixes = []string{
	"image/",
	"video/",
	"audio/",
}

var allowedMIMEExact = map[string]bool{
	"application/pdf":    true,
	"application/msword": true,
	"application/vnd.openxmlformats-officedocument.wordprocessingml.document": true,
}

func isMIMEAllowed(mime string) bool {
	for _, prefix := range allowedMIMEPrefixes {
		if strings.HasPrefix(mime, prefix) {
			return true
		}
	}
	return allowedMIMEExact[mime]
}

type EvidenceHandler struct {
	queries   *sqlcdb.Queries
	uploadDir string
}

func NewEvidenceHandler(queries *sqlcdb.Queries, uploadDir string) *EvidenceHandler {
	return &EvidenceHandler{queries: queries, uploadDir: uploadDir}
}

func (h *EvidenceHandler) Upload(c *gin.Context) {
	userID := c.GetString("userID")

	if err := c.Request.ParseMultipartForm(32 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse form"})
		return
	}

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}
	defer file.Close()

	// Detect MIME type from first 512 bytes
	buf := make([]byte, 512)
	n, _ := file.Read(buf)
	detectedMIME := http.DetectContentType(buf[:n])
	if seeker, ok := file.(io.Seeker); ok {
		seeker.Seek(0, io.SeekStart)
	}

	// Trust content-type header for formats sniffing misses
	headerMIME := header.Header.Get("Content-Type")
	mimeType := detectedMIME
	if headerMIME != "" && isMIMEAllowed(headerMIME) {
		mimeType = headerMIME
	}

	if !isMIMEAllowed(mimeType) {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("file type not allowed: %s", mimeType)})
		return
	}

	ext := filepath.Ext(header.Filename)
	newFilename := uuid.New().String() + ext

	destPath := filepath.Join(h.uploadDir, newFilename)
	dst, err := os.Create(destPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save file"})
		return
	}
	defer dst.Close()

	written, err := io.Copy(dst, file)
	if err != nil {
		os.Remove(destPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to write file"})
		return
	}

	descStr := c.PostForm("description")
	description := pgtype.Text{String: descStr, Valid: descStr != ""}

	var latitude, longitude pgtype.Float8
	if latStr := c.PostForm("latitude"); latStr != "" {
		var v float64
		if _, err := fmt.Sscanf(latStr, "%f", &v); err == nil {
			latitude = pgtype.Float8{Float64: v, Valid: true}
		}
	}
	if lonStr := c.PostForm("longitude"); lonStr != "" {
		var v float64
		if _, err := fmt.Sscanf(lonStr, "%f", &v); err == nil {
			longitude = pgtype.Float8{Float64: v, Valid: true}
		}
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		os.Remove(destPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	params := sqlcdb.CreateEvidenceParams{
		UserID:       userUUID,
		Filename:     newFilename,
		OriginalName: header.Filename,
		MimeType:     mimeType,
		FileSize:     written,
		Description:  description,
		Latitude:     latitude,
		Longitude:    longitude,
	}

	evidence, err := h.queries.CreateEvidence(c.Request.Context(), params)
	if err != nil {
		os.Remove(destPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save evidence record"})
		return
	}

	c.JSON(http.StatusCreated, evidence)
}

func (h *EvidenceHandler) List(c *gin.Context) {
	userID := c.GetString("userID")

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	items, err := h.queries.ListEvidenceByUser(c.Request.Context(), userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch evidence"})
		return
	}

	if items == nil {
		items = []sqlcdb.Evidence{}
	}

	c.JSON(http.StatusOK, items)
}

func (h *EvidenceHandler) Delete(c *gin.Context) {
	userID := c.GetString("userID")
	evidenceID := c.Param("id")

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	evidenceUUID, err := uuid.Parse(evidenceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid evidence id"})
		return
	}

	item, err := h.queries.GetEvidenceByID(c.Request.Context(), evidenceUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "evidence not found"})
		return
	}

	if item.UserID != userUUID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.queries.DeleteEvidence(c.Request.Context(), sqlcdb.DeleteEvidenceParams{
		ID:     evidenceUUID,
		UserID: userUUID,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete evidence"})
		return
	}

	os.Remove(filepath.Join(h.uploadDir, item.Filename))

	c.Status(http.StatusNoContent)
}
