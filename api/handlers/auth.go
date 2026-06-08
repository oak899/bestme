package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/oak899/growthos/api/auth"
	"github.com/oak899/growthos/api/models"
	"github.com/oak899/growthos/api/store"
)

func AuthRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/auth")
	path = strings.Trim(path, "/")
	switch {
	case path == "register" && r.Method == http.MethodPost:
		authRegister(w, r)
	case path == "login" && r.Method == http.MethodPost:
		authLogin(w, r)
	case path == "me" && r.Method == http.MethodGet:
		authMe(w, r)
	default:
		http.NotFound(w, r)
	}
}

func authRegister(w http.ResponseWriter, r *http.Request) {
	var req models.AuthRegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Email == "" || req.Password == "" {
		JSONError(w, "email and password required", http.StatusBadRequest)
		return
	}
	if len(req.Password) < 6 {
		JSONError(w, "password min 6 chars", http.StatusBadRequest)
		return
	}
	u, err := DB.CreateUser(req.Email, req.Password, req.Name)
	if err == store.ErrUserExists {
		JSONError(w, "email already registered", http.StatusConflict)
		return
	}
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	token, err := auth.IssueToken(u.ID, u.Email)
	if err != nil {
		JSONOK(w, map[string]any{"user": u, "token": ""})
		return
	}
	JSONOK(w, models.AuthResponse{Token: token, User: *u})
}

func authLogin(w http.ResponseWriter, r *http.Request) {
	var req models.AuthLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	u, err := DB.Authenticate(req.Email, req.Password)
	if err == store.ErrInvalidCredentials {
		JSONError(w, "invalid email or password", http.StatusUnauthorized)
		return
	}
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	token, err := auth.IssueToken(u.ID, u.Email)
	if err != nil {
		JSONOK(w, map[string]any{"user": u, "token": ""})
		return
	}
	JSONOK(w, models.AuthResponse{Token: token, User: *u})
}

func authMe(w http.ResponseWriter, r *http.Request) {
	claims := ClaimsFromContext(r)
	if claims == nil {
		JSONError(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	JSONOK(w, map[string]any{"id": claims.UserID, "email": claims.Email})
}
