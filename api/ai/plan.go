package ai

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/oak899/bestme/api/models"
)

const planSystem = `You are BestMe, a daily planning assistant. Given user goals for a day, output a JSON object only (no markdown) with:
{"tasks":[{"title":"...","description":"...","category":"life|work|exercise|other","needsVerification":false}],"notes":"brief planning tip"}
Mark needsVerification true for tasks like sending mail, payments, or anything requiring proof.
Balance life, work, and exercise when appropriate. Keep tasks actionable and specific.`

func GeneratePlan(date, input string) (*models.PlanResponse, error) {
	user := fmt.Sprintf("Date: %s\nUser goals and tasks for today:\n%s", date, input)
	raw, err := Complete(planSystem, user)
	if err != nil {
		return nil, err
	}
	raw = extractJSON(raw)

	var plan models.PlanResponse
	if err := json.Unmarshal([]byte(raw), &plan); err != nil {
		return nil, fmt.Errorf("parse plan: %w (raw: %s)", err, raw)
	}
	plan.Date = date
	for i := range plan.Tasks {
		if plan.Tasks[i].Category == "" {
			plan.Tasks[i].Category = models.CategoryOther
		}
	}
	return &plan, nil
}

func SummarizeDay(date string, tasks []models.Task) (string, error) {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Date: %s\nTasks:\n", date))
	for _, t := range tasks {
		sb.WriteString(fmt.Sprintf("- [%s] %s (%s) status=%s\n", t.Category, t.Title, t.Description, t.Status))
	}

	system := `Summarize the user's day in 2-4 sentences. Highlight wins, incomplete items, and items needing verification. Be encouraging and concise.`
	return Complete(system, sb.String())
}

func EventReminder(title, eventType, date string, daysUntil int) (string, error) {
	user := fmt.Sprintf("Event: %s\nType: %s\nDate: %s\nDays until: %d\nWrite a short friendly reminder (1-2 sentences) with a suggested action.", title, eventType, date, daysUntil)
	system := `You are BestMe reminder assistant. Be warm and practical.`
	return Complete(system, user)
}

func extractJSON(s string) string {
	start := strings.Index(s, "{")
	end := strings.LastIndex(s, "}")
	if start >= 0 && end > start {
		return s[start : end+1]
	}
	return s
}
