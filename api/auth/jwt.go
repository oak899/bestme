package auth

import (
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

var ErrNoSecret = errors.New("JWT_SECRET not configured")

type Claims struct {
	UserID int64  `json:"uid"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

func Secret() string {
	return os.Getenv("JWT_SECRET")
}

func Enabled() bool {
	return Secret() != ""
}

func IssueToken(userID int64, email string) (string, error) {
	sec := Secret()
	if sec == "" {
		return "", ErrNoSecret
	}
	claims := Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(sec))
}

func ParseToken(tokenStr string) (*Claims, error) {
	sec := Secret()
	if sec == "" {
		return nil, ErrNoSecret
	}
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (any, error) {
		return []byte(sec), nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}
	return claims, nil
}
