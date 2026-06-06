package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/oak899/bestme/api/db"
	"github.com/oak899/bestme/api/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func TasksRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/tasks")
	path = strings.Trim(path, "/")

	switch {
	case path == "" && r.Method == http.MethodGet:
		listTasks(w, r)
	case path == "" && r.Method == http.MethodPost:
		createTask(w, r)
	case path == "generate-routines" && r.Method == http.MethodPost:
		generateRoutineTasks(w, r)
	case strings.HasSuffix(path, "/status") && r.Method == http.MethodPatch:
		updateTaskStatus(w, r, strings.TrimSuffix(path, "/status"))
	case path != "" && r.Method == http.MethodDelete:
		deleteTask(w, r, path)
	default:
		http.Error(w, "not found", http.StatusNotFound)
	}
}

func listTasks(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	category := r.URL.Query().Get("category")

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	filter := bson.M{"date": date}
	if category != "" {
		filter["category"] = category
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	cur, err := col.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}}))
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
	JSONOK(w, tasks)
}

func createTask(w http.ResponseWriter, r *http.Request) {
	var t models.Task
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if t.Title == "" {
		JSONError(w, "title required", http.StatusBadRequest)
		return
	}
	if t.Date == "" {
		t.Date = time.Now().Format("2006-01-02")
	}
	if t.Category == "" {
		t.Category = models.CategoryOther
	}
	if t.Status == "" {
		t.Status = models.StatusPending
	}
	if t.NeedsVerification {
		t.Status = models.StatusNeedsVerification
	}
	t.CreatedAt = time.Now()

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	res, err := col.InsertOne(ctx, t)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	t.ID = res.InsertedID.(primitive.ObjectID)
	JSONOK(w, t)
}

type statusBody struct {
	Status string `json:"status"`
}

func updateTaskStatus(w http.ResponseWriter, r *http.Request, id string) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}

	var body statusBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}

	switch body.Status {
	case models.StatusPending, models.StatusDone, models.StatusNeedsVerification:
	default:
		JSONError(w, "invalid status", http.StatusBadRequest)
		return
	}

	update := bson.M{"status": body.Status}
	if body.Status == models.StatusDone {
		now := time.Now()
		update["completedAt"] = now
	}

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	_, err = col.UpdateByID(ctx, oid, bson.M{"$set": update})
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var task models.Task
	_ = col.FindOne(ctx, bson.M{"_id": oid}).Decode(&task)
	JSONOK(w, task)
}

func deleteTask(w http.ResponseWriter, r *http.Request, id string) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}

	col, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	_, err = col.DeleteOne(ctx, bson.M{"_id": oid})
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func generateRoutineTasks(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Date string `json:"date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Date == "" {
		req.Date = time.Now().Format("2006-01-02")
	}

	rCol, err := db.Collection("routines")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	tCol, err := db.Collection("tasks")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
	defer cancel()

	cur, err := rCol.Find(ctx, bson.M{"active": true})
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var routines []models.Routine
	if err := cur.All(ctx, &routines); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	created := []models.Task{}
	for _, routine := range routines {
		count, _ := tCol.CountDocuments(ctx, bson.M{
			"date":      req.Date,
			"routineId": routine.ID.Hex(),
		})
		if count > 0 {
			continue
		}

		status := models.StatusPending
		if routine.NeedsVerification {
			status = models.StatusNeedsVerification
		}

		task := models.Task{
			Title:             routine.Title,
			Description:       routine.Description,
			Category:          routine.Category,
			Date:              req.Date,
			Status:            status,
			RoutineID:         routine.ID.Hex(),
			NeedsVerification: routine.NeedsVerification,
			CreatedAt:         time.Now(),
		}
		res, err := tCol.InsertOne(ctx, task)
		if err != nil {
			continue
		}
		task.ID = res.InsertedID.(primitive.ObjectID)
		created = append(created, task)
	}

	JSONOK(w, map[string]interface{}{
		"date":    req.Date,
		"created": created,
		"count":   len(created),
	})
}
