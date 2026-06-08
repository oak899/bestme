package store

import (
	"database/sql"
	"errors"

	"github.com/oak899/growthos/api/models"
	"golang.org/x/crypto/bcrypt"
)

var ErrUserExists = errors.New("user already exists")
var ErrInvalidCredentials = errors.New("invalid credentials")

func (s *Store) CreateUser(email, password, name string) (*models.User, error) {
	var n int
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM users WHERE email=? COLLATE NOCASE`, email).Scan(&n)
	if n > 0 {
		return nil, ErrUserExists
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	res, err := s.db.Exec(`INSERT INTO users (email, password_hash, name) VALUES (?,?,?)`, email, string(hash), name)
	if err != nil {
		return nil, err
	}
	id, _ := res.LastInsertId()
	return &models.User{ID: id, Email: email, Name: name}, nil
}

func (s *Store) Authenticate(email, password string) (*models.User, error) {
	var u models.User
	var hash string
	err := s.db.QueryRow(`SELECT id, email, name, password_hash, created_at FROM users WHERE email=? COLLATE NOCASE`, email).
		Scan(&u.ID, &u.Email, &u.Name, &hash, &u.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, ErrInvalidCredentials
	}
	if err != nil {
		return nil, err
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) != nil {
		return nil, ErrInvalidCredentials
	}
	return &u, nil
}
