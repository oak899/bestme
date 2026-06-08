package models

// Jira-style task statuses (GrowthOS)
const (
	StatusBacklog    = "backlog"
	StatusTodo       = "todo"
	StatusInProgress = "in_progress"
	StatusBlocked    = "blocked"
)

const (
	PriorityHigh   = "high"
	PriorityMedium = "medium"
	PriorityLow    = "low"
)

type Project struct {
	ID          int64   `json:"id"`
	Name        string  `json:"name"`
	Goal        string  `json:"goal,omitempty"`
	StartDate   string  `json:"startDate,omitempty"`
	EndDate     string  `json:"endDate,omitempty"`
	ProgressPct float64 `json:"progressPct"`
	Color       string  `json:"color"`
	Archived    bool    `json:"archived"`
	CreatedAt   string  `json:"createdAt,omitempty"`
	TaskTotal     int `json:"taskTotal,omitempty"`
	TaskDone      int `json:"taskDone,omitempty"`
	TotalMinutes  int `json:"totalMinutes,omitempty"`
}

type DailyPlan struct {
	ID               int64  `json:"id"`
	PlanDate         string `json:"planDate"`
	FocusGoals       string `json:"focusGoals"`
	EstimatedMinutes int    `json:"estimatedMinutes"`
	ActualMinutes    int    `json:"actualMinutes"`
	Review           string `json:"review"`
	TomorrowImprove  string `json:"tomorrowImprove"`
	AIGenerated      bool   `json:"aiGenerated"`
	CreatedAt        string `json:"createdAt,omitempty"`
}

type Dashboard struct {
	Date              string     `json:"date"`
	Quote             string     `json:"quote"`
	TodayMinutes      int        `json:"todayMinutes"`
	WeekCompletionPct int        `json:"weekCompletionPct"`
	InProgress        []Task     `json:"inProgress"`
	Todo              []Task     `json:"todo"`
	Done              []Task     `json:"done"`
	DailyPlan         *DailyPlan `json:"dailyPlan,omitempty"`
}

type TimeEntry struct {
	ID              int64  `json:"id"`
	TaskID          int64  `json:"taskId"`
	StartedAt       string `json:"startedAt"`
	EndedAt         string `json:"endedAt,omitempty"`
	DurationMinutes int    `json:"durationMinutes"`
	PausedTotalSec  int    `json:"pausedTotalSec"`
	PausedAt        string `json:"pausedAt,omitempty"`
	IsPaused        bool   `json:"isPaused"`
}

type KanbanColumn struct {
	Status string `json:"status"`
	Tasks  []Task `json:"tasks"`
}

type KanbanReorderRequest struct {
	Updates []KanbanReorderItem `json:"updates"`
}

type KanbanReorderItem struct {
	ID        int64  `json:"id"`
	Status    string `json:"status"`
	SortOrder int    `json:"sortOrder"`
}

type UserSettings struct {
	DailyGoalMinutes   int    `json:"dailyGoalMinutes"`
	WorkDays           string `json:"workDays"`
	DefaultPriority    string `json:"defaultPriority"`
	Theme              string `json:"theme"`
	GrowthGoal         string `json:"growthGoal"`
	DailyPlanRemindAt  string `json:"dailyPlanRemindAt"`
}

type TimeStats struct {
	Date           string `json:"date"`
	TotalMinutes   int    `json:"totalMinutes"`
	WeekTotalMins  int    `json:"weekTotalMinutes"`
	DayGoalMinutes int    `json:"dayGoalMinutes"`
}

type ReportsData struct {
	Date                   string          `json:"date"`
	Period                 string          `json:"period"`
	Days                   int             `json:"days"`
	DailyCompletion        []DayCompletion `json:"dailyCompletion"`
	ProjectTimeShare       []ProjectShare  `json:"projectTimeShare"`
	WeekCompletionPct      int             `json:"weekCompletionPct"`
	HighPriorityCompletion int             `json:"highPriorityCompletionPct"`
	OverdueCount           int             `json:"overdueCount"`
	TotalWorkMinutes       int             `json:"totalWorkMinutes"`
	HourlyDistribution     []HourBucket    `json:"hourlyDistribution"`
}

type HourBucket struct {
	Hour    int `json:"hour"`
	Minutes int `json:"minutes"`
}

type DayCompletion struct {
	Date       string `json:"date"`
	Total      int    `json:"total"`
	Completed  int    `json:"completed"`
	Pct        int    `json:"pct"`
}

type ProjectShare struct {
	ProjectID   int64   `json:"projectId"`
	ProjectName string  `json:"projectName"`
	Minutes     int     `json:"minutes"`
	Pct         float64 `json:"pct"`
}
