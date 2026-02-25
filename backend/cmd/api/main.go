package main

import (
	"context"
	"log"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"poco/internal/config"
	"poco/internal/db"
	sqlcdb "poco/internal/db/sqlc"
	"poco/internal/handlers"
	"poco/internal/middleware"
	"poco/internal/ws"
)

func main() {
	// Load .env if present (ignored in production where env vars are set directly)
	_ = godotenv.Load()

	cfg := config.Load()

	ctx := context.Background()

	pool, err := db.NewPool(ctx, cfg.DBUrl)
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer pool.Close()

	if err := db.RunMigrations(ctx, pool); err != nil {
		log.Fatalf("migrations failed: %v", err)
	}
	log.Println("migrations applied")

	if err := os.MkdirAll(cfg.UploadDir, 0755); err != nil {
		log.Fatalf("failed to create upload dir: %v", err)
	}

	queries := sqlcdb.New(pool)

	hub := ws.NewHub()
	go hub.Run()

	authHandler := handlers.NewAuthHandler(queries, cfg.JWTSecret)
	userHandler := handlers.NewUserHandler(queries)
	msgHandler := handlers.NewMessageHandler(queries, hub)
	wsHandler := handlers.NewWSHandler(hub, queries, cfg.JWTSecret)
	evidenceHandler := handlers.NewEvidenceHandler(queries, cfg.UploadDir)
	containerHandler := handlers.NewContainerHandler(queries)

	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     cfg.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	api := r.Group("/api")
	{
		authGroup := api.Group("/auth")
		{
			authGroup.POST("/register", authHandler.Register)
			authGroup.POST("/login", authHandler.Login)
		}

		protected := api.Group("/")
		protected.Use(middleware.AuthMiddleware(cfg.JWTSecret))
		{
			protected.GET("/users", userHandler.ListUsers)
			protected.POST("/messages", msgHandler.SendMessage)
			protected.GET("/messages/:userId", msgHandler.GetMessages)
			protected.POST("/evidence", evidenceHandler.Upload)
			protected.DELETE("/evidence/:id", evidenceHandler.Delete)
			protected.POST("/containers", containerHandler.Create)
			protected.GET("/containers", containerHandler.List)
			protected.DELETE("/containers/:id", containerHandler.Delete)
			protected.GET("/containers/:id/evidence", containerHandler.ListEvidence)
		}
	}

	r.Static("/api/uploads", cfg.UploadDir)

	// WebSocket endpoint — auth via ?token= query param
	r.GET("/ws", wsHandler.HandleWS)

	log.Printf("server listening on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
