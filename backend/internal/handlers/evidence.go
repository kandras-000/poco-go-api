package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	sqlcdb "poco/internal/db/sqlc"
)

type EvidenceResponse struct {
	ID           uuid.UUID  `json:"id"`
	UserID       uuid.UUID  `json:"user_id"`
	ContainerID  *string    `json:"container_id"`
	Filename     string     `json:"filename"`
	OriginalName string     `json:"original_name"`
	MimeType     string     `json:"mime_type"`
	FileSize     int64      `json:"file_size"`
	Description  *string    `json:"description"`
	Latitude     *float64   `json:"latitude"`
	Longitude    *float64   `json:"longitude"`
	CreatedAt    time.Time  `json:"created_at"`
}

func toEvidenceResponse(e sqlcdb.Evidence) EvidenceResponse {
	r := EvidenceResponse{
		ID:           e.ID,
		UserID:       e.UserID,
		Filename:     e.Filename,
		OriginalName: e.OriginalName,
		MimeType:     e.MimeType,
		FileSize:     e.FileSize,
		CreatedAt:    e.CreatedAt,
	}
	if e.ContainerID.Valid {
		s := uuid.UUID(e.ContainerID.Bytes).String()
		r.ContainerID = &s
	}
	if e.Description.Valid {
		r.Description = &e.Description.String
	}
	if e.Latitude.Valid {
		r.Latitude = &e.Latitude.Float64
	}
	if e.Longitude.Valid {
		r.Longitude = &e.Longitude.Float64
	}
	return r
}

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

	containerIDStr := c.PostForm("container_id")
	if containerIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "container_id is required"})
		return
	}
	containerUUID, err := uuid.Parse(containerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid container_id"})
		return
	}

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}
	defer file.Close()

	buf := make([]byte, 512)
	n, _ := file.Read(buf)
	detectedMIME := http.DetectContentType(buf[:n])
	if seeker, ok := file.(io.Seeker); ok {
		seeker.Seek(0, io.SeekStart)
	}

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

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		os.Remove(destPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user id"})
		return
	}

	descStr := c.PostForm("description")
	description := pgtype.Text{String: descStr, Valid: descStr != ""}

	latStr := c.PostForm("latitude")
	lonStr := c.PostForm("longitude")
	log.Printf("Upload: lat=%q lon=%q", latStr, lonStr)

	var latitude, longitude pgtype.Float8
	if latStr != "" {
		if v, err := strconv.ParseFloat(latStr, 64); err == nil {
			latitude = pgtype.Float8{Float64: v, Valid: true}
		} else {
			log.Printf("Upload: failed to parse latitude %q: %v", latStr, err)
		}
	}
	if lonStr != "" {
		if v, err := strconv.ParseFloat(lonStr, 64); err == nil {
			longitude = pgtype.Float8{Float64: v, Valid: true}
		} else {
			log.Printf("Upload: failed to parse longitude %q: %v", lonStr, err)
		}
	}

	evidence, err := h.queries.CreateEvidence(c.Request.Context(), sqlcdb.CreateEvidenceParams{
		UserID:       userUUID,
		ContainerID:  pgtype.UUID{Bytes: [16]byte(containerUUID), Valid: true},
		Filename:     newFilename,
		OriginalName: header.Filename,
		MimeType:     mimeType,
		FileSize:     written,
		Description:  description,
		Latitude:     latitude,
		Longitude:    longitude,
	})
	if err != nil {
		os.Remove(destPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save evidence record"})
		return
	}

	c.JSON(http.StatusCreated, toEvidenceResponse(evidence))
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
