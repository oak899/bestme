package models

const (
	CategoryLife     = "life"
	CategoryWork     = "work"
	CategoryExercise = "exercise"
	CategoryOther    = "other"

	StatusPending           = "pending"
	StatusDone              = "done"
	StatusNeedsVerification = "needs_verification"

	EventBirthday = "birthday"
	EventCustom   = "event"
)

var ValidCategories = []string{CategoryLife, CategoryWork, CategoryExercise, CategoryOther}

type Task struct {
	ID                int64    `json:"id"`
	Title             string   `json:"title"`
	Description       string   `json:"description,omitempty"`
	Category          string   `json:"category"`
	Date              string   `json:"date"`
	Status            string   `json:"status"`
	Priority          string   `json:"priority"`
	ProjectID         *int64   `json:"projectId,omitempty"`
	ParentID          *int64   `json:"parentId,omitempty"`
	DueDate           string   `json:"dueDate,omitempty"`
	EstimateMinutes   int      `json:"estimateMinutes"`
	ActualMinutes     int      `json:"actualMinutes"`
	Tags              []string `json:"tags"`
	SortOrder         int      `json:"sortOrder"`
	RoutineID         int64    `json:"routineId,omitempty"`
	AIGenerated       bool     `json:"aiGenerated"`
	NeedsVerification bool     `json:"needsVerification"`
	CreatedAt         string   `json:"createdAt,omitempty"`
	UpdatedAt         string   `json:"updatedAt,omitempty"`
	CompletedAt       string   `json:"completedAt,omitempty"`
}

type TaskHistory struct {
	ID         int64  `json:"id"`
	TaskID     int64  `json:"taskId"`
	FromStatus string `json:"fromStatus"`
	ToStatus   string `json:"toStatus"`
	ChangedAt  string `json:"changedAt"`
	Note       string `json:"note,omitempty"`
}

type TaskComment struct {
	ID        int64  `json:"id"`
	TaskID    int64  `json:"taskId"`
	Body      string `json:"body"`
	CreatedAt string `json:"createdAt"`
}

type Routine struct {
	ID                int64  `json:"id"`
	Title             string `json:"title"`
	Description       string `json:"description,omitempty"`
	Category          string `json:"category"`
	NeedsVerification bool   `json:"needsVerification"`
	Active            bool   `json:"active"`
	CreatedAt         string `json:"createdAt,omitempty"`
}

type Event struct {
	ID               int64  `json:"id"`
	Title            string `json:"title"`
	Type             string `json:"type"`
	Date             string `json:"date"`
	RemindDaysBefore int    `json:"remindDaysBefore"`
	Notes            string `json:"notes,omitempty"`
	CreatedAt        string `json:"createdAt,omitempty"`
}

type DailySummary struct {
	Date              string                   `json:"date"`
	Total             int                      `json:"total"`
	Completed         int                      `json:"completed"`
	Pending           int                      `json:"pending"`
	NeedsVerification int                      `json:"needsVerification"`
	ByCategory        map[string]CategoryStats `json:"byCategory"`
	AISummary         string                   `json:"aiSummary,omitempty"`
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
	Date  string      `json:"date"`
	Tasks []TaskDraft `json:"tasks"`
	Notes string      `json:"notes,omitempty"`
}

type TaskDraft struct {
	Title             string `json:"title"`
	Description       string `json:"description,omitempty"`
	Category          string `json:"category"`
	NeedsVerification bool   `json:"needsVerification"`
}

type TaskSummary struct {
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
	Category    string `json:"category"`
	Status      string `json:"status"`
}

type SummaryRequest struct {
	Date string `json:"date"`
}

type ReminderItem struct {
	EventID   int64  `json:"eventId"`
	Title     string `json:"title"`
	Type      string `json:"type"`
	Date      string `json:"date"`
	DaysUntil int    `json:"daysUntil"`
	AIMessage string `json:"aiMessage,omitempty"`
}
