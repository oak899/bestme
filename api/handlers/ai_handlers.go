package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/oak899/bestme/api/ai"
	"github.com/oak899/bestme/api/db"
	"github.com/oak899/bestme/api/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
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
	default:
		http.Error(w, "not found", http.StatusNotFound)
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

func applyPlan(w http.ResponseWriter, r *http.Request) {
	var plan models.PlanResponse
	if err := json.NewDecoder(r.Body).Decode(&plan); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if plan.Date == "" {
		plan.Date = time.Now().Format("2006-01-02")
	}

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
	defer cancel()

	created := []models.Task{}
	for _, draft := range plan.Tasks {
		status := models.StatusPending
		if draft.NeedsVerification {
			status = models.StatusNeedsVerification
		}
		task := models.Task{
			Title:             draft.Title,
			Description:       draft.Description,
			Category:          draft.Category,
			Date:              plan.Date,
			Status:            status,
			AIGenerated:       true,
			NeedsVerification: draft.NeedsVerification,
			CreatedAt:         time.Now(),
		}
		res, err := col.InsertOne(ctx, task)
		if err != nil {
			continue
		}
		task.ID = res.InsertedID.(primitive.ObjectID)
		created = append(created, task)
	}

	JSONOK(w, map[string]interface{}{
		"created": created,
		"count":   len(created),
		"notes":   plan.Notes,
	})
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

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()

	cur, err := col.Find(ctx, bson.M{"date": req.Date}, options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}}))
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var tasks []models.Task
	if err := cur.All(ctx, &tasks); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if tasks == nil {
		tasks = []models.Task{}
	}

	summary := buildSummary(req.Date, tasks)
	text, err := ai.SummarizeDay(req.Date, tasks)
	if err == nil {
		summary.AISummary = text
	}

	JSONOK(w, summary)
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
