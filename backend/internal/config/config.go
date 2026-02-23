package config

import (
	"os"
	"strings"
)

type Config struct {
	DBUrl       string
	JWTSecret   string
	Port        string
	CORSOrigins []string
}

func Load() Config {
	return Config{
		DBUrl:       getEnv("DATABASE_URL", "postgres://poco:poco_password@localhost:5432/poco_db?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "change-me-in-production"),
		Port:        getEnv("PORT", "8080"),
		CORSOrigins: strings.Split(getEnv("CORS_ORIGINS", "http://localhost:5173"), ","),
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
