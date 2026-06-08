package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/oak899/bestme/api/models"
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
	case strings.HasSuffix(path, "/comments") && r.Method == http.MethodGet:
		listComments(w, r, strings.TrimSuffix(path, "/comments"))
	case strings.HasSuffix(path, "/comments") && r.Method == http.MethodPost:
		addComment(w, r, strings.TrimSuffix(path, "/comments"))
	case strings.HasSuffix(path, "/history") && r.Method == http.MethodGet:
		listHistory(w, r, strings.TrimSuffix(path, "/history"))
	case strings.HasSuffix(path, "/subtasks") && r.Method == http.MethodGet:
		listSubtasks(w, r, strings.TrimSuffix(path, "/subtasks"))
	case path != "" && !strings.Contains(path, "/") && r.Method == http.MethodGet:
		getTask(w, r, path)
	case path != "" && !strings.Contains(path, "/") && r.Method == http.MethodPut:
		updateTask(w, r, path)
	case path != "" && !strings.Contains(path, "/") && r.Method == http.MethodDelete:
		deleteTask(w, r, path)
	default:
		http.NotFound(w, r)
	}
}

func listTasks(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	status := r.URL.Query().Get("status")
	category := r.URL.Query().Get("category")
	pid, _ := strconv.ParseInt(r.URL.Query().Get("project_id"), 10, 64)
	parid, _ := strconv.ParseInt(r.URL.Query().Get("parent_id"), 10, 64)
	tasks, err := DB.ListTasksFiltered(date, category, status, pid, parid)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if tasks == nil {
		tasks = []models.Task{}
	}
	JSONOK(w, tasks)
}

func getTask(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	t, err := DB.GetTask(id)
	if err != nil {
		JSONError(w, err.Error(), http.StatusNotFound)
		return
	}
	JSONOK(w, t)
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
	if err := DB.CreateTask(&t); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, t)
}

func updateTask(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	var t models.Task
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	t.ID = id
	if t.Title == "" {
		JSONError(w, "title required", http.StatusBadRequest)
		return
	}
	updated, err := DB.UpdateTask(&t)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, updated)
}

type statusBody struct {
	Status string `json:"status"`
}

func updateTaskStatus(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(strings.Trim(idStr, "/"), 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	var body statusBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if !validStatus(body.Status) {
		JSONError(w, "invalid status", http.StatusBadRequest)
		return
	}
	task, err := DB.UpdateTaskStatus(id, body.Status)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, task)
}

func validStatus(s string) bool {
	switch s {
	case models.StatusPending, models.StatusDone, models.StatusNeedsVerification,
		models.StatusBacklog, models.StatusTodo, models.StatusInProgress, models.StatusBlocked:
		return true
	}
	return false
}

func listSubtasks(w http.ResponseWriter, r *http.Request, idStr string) {
	id, _ := strconv.ParseInt(strings.Trim(idStr, "/"), 10, 64)
	tasks, err := DB.ListSubtasks(id)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if tasks == nil {
		tasks = []models.Task{}
	}
	JSONOK(w, tasks)
}

func listHistory(w http.ResponseWriter, r *http.Request, idStr string) {
	id, _ := strconv.ParseInt(idStr, 10, 64)
	h, err := DB.ListTaskHistory(id)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if h == nil {
		h = []models.TaskHistory{}
	}
	JSONOK(w, h)
}

func listComments(w http.ResponseWriter, r *http.Request, idStr string) {
	id, _ := strconv.ParseInt(idStr, 10, 64)
	c, err := DB.ListTaskComments(id)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if c == nil {
		c = []models.TaskComment{}
	}
	JSONOK(w, c)
}

func addComment(w http.ResponseWriter, r *http.Request, idStr string) {
	id, _ := strconv.ParseInt(idStr, 10, 64)
	var body struct {
		Body string `json:"body"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Body == "" {
		JSONError(w, "body required", http.StatusBadRequest)
		return
	}
	c, err := DB.AddTaskComment(id, body.Body)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, c)
}

func deleteTask(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := DB.DeleteTask(id); err != nil {
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
	created, err := DB.GenerateRoutineTasks(req.Date)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if created == nil {
		created = []models.Task{}
	}
	JSONOK(w, map[string]any{"date": req.Date, "created": created, "count": len(created)})
}
