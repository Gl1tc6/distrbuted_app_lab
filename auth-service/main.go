package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
    
    "github.com/golang-jwt/jwt/v5"
    "github.com/gorilla/mux"
    "github.com/rs/cors"
)

type Credentials struct {
    Username string `json:"username"`
    Password string `json:"password"`
}

type TokenResponse struct {
    Token   string `json:"token"`
    Expires string `json:"expires"`
}

var jwtSecret = []byte(getEnv("JWT_SECRET", "auth-secret"))

func main() {
    r := mux.NewRouter()
    
    // Health check
    r.HandleFunc("/health", healthHandler).Methods("GET")
    
    // Auth endpoints
    r.HandleFunc("/auth/validate", validateTokenHandler).Methods("POST")
    r.HandleFunc("/auth/refresh", refreshTokenHandler).Methods("POST")
    
    // CORS middleware
    c := cors.New(cors.Options{
        AllowedOrigins:   []string{"*"},
        AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowedHeaders:   []string{"*"},
        AllowCredentials: true,
    })
    
    handler := c.Handler(r)
    
    port := getEnv("PORT", "8080")
    log.Printf("Auth service starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, handler))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    response := map[string]interface{}{
        "status":    "healthy",
        "service":   "auth-service",
        "version":   "1.0.0",
        "timestamp": time.Now(),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func validateTokenHandler(w http.ResponseWriter, r *http.Request) {
    authHeader := r.Header.Get("Authorization")
    if authHeader == "" {
        http.Error(w, "Missing Authorization header", http.StatusUnauthorized)
        return
    }
    
    tokenString := authHeader[7:] // Remove "Bearer "
    
    token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method")
        }
        return jwtSecret, nil
    })
    
    if err != nil || !token.Valid {
        http.Error(w, "Invalid token", http.StatusUnauthorized)
        return
    }
    
    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok {
        http.Error(w, "Invalid token claims", http.StatusUnauthorized)
        return
    }
    
    response := map[string]interface{}{
        "valid":    true,
        "username": claims["username"],
        "role":     claims["role"],
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func refreshTokenHandler(w http.ResponseWriter, r *http.Request) {
    // Simplified refresh logic
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "username": "admin",
        "role":     "admin",
        "exp":      time.Now().Add(time.Hour).Unix(),
    })
    
    tokenString, err := token.SignedString(jwtSecret)
    if err != nil {
        http.Error(w, "Error generating token", http.StatusInternalServerError)
        return
    }
    
    response := TokenResponse{
        Token:   tokenString,
        Expires: time.Now().Add(time.Hour).Format(time.RFC3339),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}