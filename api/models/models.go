package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	CategoryLife     = "life"
	CategoryWork     = "work"
	CategoryExercise = "exercise"
	CategoryOther    = "other"

	StatusPending            = "pending"
	StatusDone               = "done"
	StatusNeedsVerification  = "needs_verification"

	EventBirthday = "birthday"
	EventCustom   = "event"
)

var ValidCategories = []string{CategoryLife, CategoryWork, CategoryExercise, CategoryOther}

type Task struct {
	ID                primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title             string             `bson:"title" json:"title"`
	Description       string             `bson:"description,omitempty" json:"description,omitempty"`
	Category          string             `bson:"category" json:"category"`
	Date              string             `bson:"date" json:"date"`
	Status            string             `bson:"status" json:"status"`
	RoutineID         string             `bson:"routineId,omitempty" json:"routineId,omitempty"`
	AIGenerated       bool               `bson:"aiGenerated" json:"aiGenerated"`
	NeedsVerification bool               `bson:"needsVerification" json:"needsVerification"`
	CreatedAt         time.Time          `bson:"createdAt" json:"createdAt"`
	CompletedAt       *time.Time         `bson:"completedAt,omitempty" json:"completedAt,omitempty"`
}

type Routine struct {
	ID                primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title             string             `bson:"title" json:"title"`
	Description       string             `bson:"description,omitempty" json:"description,omitempty"`
	Category          string             `bson:"category" json:"category"`
	NeedsVerification bool               `bson:"needsVerification" json:"needsVerification"`
	Active            bool               `bson:"active" json:"active"`
	CreatedAt         time.Time          `bson:"createdAt" json:"createdAt"`
}

type Event struct {
	ID               primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title            string             `bson:"title" json:"title"`
	Type             string             `bson:"type" json:"type"`
	Date             string             `bson:"date" json:"date"`
	RemindDaysBefore int                `bson:"remindDaysBefore" json:"remindDaysBefore"`
	Notes            string             `bson:"notes,omitempty" json:"notes,omitempty"`
	CreatedAt        time.Time          `bson:"createdAt" json:"createdAt"`
}

type DailySummary struct {
	Date               string   `json:"date"`
	Total              int      `json:"total"`
	Completed          int      `json:"completed"`
	Pending            int      `json:"pending"`
	NeedsVerification  int      `json:"needsVerification"`
	ByCategory         map[string]CategoryStats `json:"byCategory"`
	AISummary          string   `json:"aiSummary,omitempty"`
}

type CategoryStats struct {
	Total     int `json:"total"`
	Completed int `json:"completed"`
}

type PlanRequest struct {
	Date  string `json:"date"`
	Input string `json:"input"`
}

type PlanResponse struct {
	Date  string       `json:"date"`
	Tasks []TaskDraft  `json:"tasks"`
	Notes string       `json:"notes,omitempty"`
}

type TaskDraft struct {
	Title             string `json:"title"`
	Description       string `json:"description,omitempty"`
	Category          string `json:"category"`
	NeedsVerification bool   `json:"needsVerification"`
}

type SummaryRequest struct {
	Date string `json:"date"`
}

type ReminderItem struct {
	EventID   string `json:"eventId"`
	Title     string `json:"title"`
	Type      string `json:"type"`
	Date      string `json:"date"`
	DaysUntil int    `json:"daysUntil"`
	AIMessage string `json:"aiMessage,omitempty"`
}
