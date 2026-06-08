package handlers

import (
	"context"
	"net/http"
	"strings"

	"github.com/oak899/bestme/api/auth"
)

type ctxKey int

const claimsKey ctxKey = 1

func ClaimsFromContext(r *http.Request) *auth.Claims {
	c, _ := r.Context().Value(claimsKey).(*auth.Claims)
	return c
}

func WithAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !auth.Enabled() {
			next(w, r)
			return
		}
		if isPublicPath(r.URL.Path) {
			next(w, r)
			return
		}
		h := r.Header.Get("Authorization")
		if !strings.HasPrefix(h, "Bearer ") {
			JSONError(w, "authorization required", http.StatusUnauthorized)
			return
		}
		claims, err := auth.ParseToken(strings.TrimPrefix(h, "Bearer "))
		if err != nil {
			JSONError(w, "invalid token", http.StatusUnauthorized)
			return
		}
		ctx := context.WithValue(r.Context(), claimsKey, claims)
		next(w, r.WithContext(ctx))
	}
}

func isPublicPath(path string) bool {
	if path == "/api" || path == "/api/" {
		return true
	}
	if strings.HasPrefix(path, "/api/auth/") {
		return true
	}
	return false
}
