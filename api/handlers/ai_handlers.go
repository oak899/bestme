package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/oak899/growthos/api/ai"
	"github.com/oak899/growthos/api/models"
)

func AIRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/ai")
	path = strings.Trim(path, "/")

	switch {
	case path == "plan" && r.Method == http.MethodPost:
		aiPlan(w, r)
	case path == "summary" && r.Method == http.MethodPost:
		aiSummary(w, r)
	case path == "apply-plan" && r.Method == http.MethodPost:
		applyPlan(w, r)
	case path == "plan-and-apply" && r.Method == http.MethodPost:
		planAndApply(w, r)
	case path == "reminder" && r.Method == http.MethodPost:
		aiReminder(w, r)
	default:
		http.NotFound(w, r)
	}
}

func aiPlan(w http.ResponseWriter, r *http.Request) {
	var req models.PlanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Date == "" {
		req.Date = time.Now().Format("2006-01-02")
	}
	if req.Input == "" {
		JSONError(w, "input required", http.StatusBadRequest)
		return
	}
	plan, err := ai.GeneratePlan(req.Date, req.Input)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, plan)
}

func planAndApply(w http.ResponseWriter, r *http.Request) {
	var req models.PlanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Date == "" {
		req.Date = time.Now().Format("2006-01-02")
	}
	if req.Input == "" {
		JSONError(w, "input required", http.StatusBadRequest)
		return
	}
	plan, err := ai.GeneratePlan(req.Date, req.Input)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	created := savePlanTasks(*plan)
	JSONOK(w, map[string]any{
		"date":    plan.Date,
		"count":   len(created),
		"created": created,
		"notes":   plan.Notes,
		"plan":    plan,
	})
}

func applyPlan(w http.ResponseWriter, r *http.Request) {
	var plan models.PlanResponse
	if err := json.NewDecoder(r.Body).Decode(&plan); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if plan.Date == "" {
		plan.Date = time.Now().Format("2006-01-02")
	}
	created := savePlanTasks(plan)
	JSONOK(w, map[string]any{"created": created, "count": len(created), "notes": plan.Notes})
}

func savePlanTasks(plan models.PlanResponse) []models.Task {
	created := []models.Task{}
	for _, draft := range plan.Tasks {
		cat := draft.Category
		if cat == "" {
			cat = models.CategoryOther
		}
		status := models.StatusPending
		if draft.NeedsVerification {
			status = models.StatusNeedsVerification
		}
		t := models.Task{
			Title:             draft.Title,
			Description:       draft.Description,
			Category:          cat,
			Date:              plan.Date,
			Status:            status,
			AIGenerated:       true,
			NeedsVerification: draft.NeedsVerification,
		}
		if err := DB.CreateTask(&t); err != nil {
			continue
		}
		created = append(created, t)
	}
	return created
}

func aiSummary(w http.ResponseWriter, r *http.Request) {
	var req models.SummaryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Date == "" {
		req.Date = time.Now().Format("2006-01-02")
	}
	tasks, err := DB.ListTasks(req.Date, "")
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	summary := buildSummary(req.Date, tasks)
	if text, err := ai.SummarizeDay(req.Date, tasks); err == nil {
		summary.AISummary = text
	}
	JSONOK(w, summary)
}

type reminderRequest struct {
	Title     string `json:"title"`
	Type      string `json:"type"`
	Date      string `json:"date"`
	DaysUntil int    `json:"daysUntil"`
}

func aiReminder(w http.ResponseWriter, r *http.Request) {
	var req reminderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Title == "" {
		JSONError(w, "title required", http.StatusBadRequest)
		return
	}
	msg, err := ai.EventReminder(req.Title, req.Type, req.Date, req.DaysUntil)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, map[string]string{"message": msg})
}

func buildSummary(date string, tasks []models.Task) models.DailySummary {
	s := models.DailySummary{
		Date:       date,
		ByCategory: map[string]models.CategoryStats{},
	}
	for _, cat := range models.ValidCategories {
		s.ByCategory[cat] = models.CategoryStats{}
	}
	for _, t := range tasks {
		s.Total++
		stats := s.ByCategory[t.Category]
		stats.Total++
		switch t.Status {
		case models.StatusDone:
			s.Completed++
			stats.Completed++
		case models.StatusNeedsVerification:
			s.NeedsVerification++
		default:
			s.Pending++
		}
		s.ByCategory[t.Category] = stats
	}
	return s
}
