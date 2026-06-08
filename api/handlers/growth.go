package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/oak899/bestme/api/models"
)

func DashboardRouter(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.NotFound(w, r)
		return
	}
	date := r.URL.Query().Get("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	d, err := DB.Dashboard(date)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, d)
}

func DailyPlansRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/daily-plans")
	path = strings.Trim(path, "/")

	switch {
	case path == "copy-yesterday" && r.Method == http.MethodPost:
		copyYesterdayPlan(w, r)
	case path == "" && r.Method == http.MethodGet:
		getDailyPlan(w, r)
	case path == "" && r.Method == http.MethodPost:
		upsertDailyPlan(w, r)
	default:
		http.NotFound(w, r)
	}
}

func getDailyPlan(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	p, err := DB.GetDailyPlan(date)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if p == nil {
		JSONOK(w, map[string]any{"planDate": date, "focusGoals": ""})
		return
	}
	JSONOK(w, p)
}

func upsertDailyPlan(w http.ResponseWriter, r *http.Request) {
	var p models.DailyPlan
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if p.PlanDate == "" {
		p.PlanDate = time.Now().Format("2006-01-02")
	}
	if err := DB.UpsertDailyPlan(&p); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, p)
}

func copyYesterdayPlan(w http.ResponseWriter, r *http.Request) {
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
	t, _ := time.Parse("2006-01-02", req.Date)
	yesterday := t.AddDate(0, 0, -1).Format("2006-01-02")
	p, err := DB.CopyDailyPlan(yesterday, req.Date)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, p)
}

func ProjectsRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/projects")
	path = strings.Trim(path, "/")

	switch {
	case path == "" && r.Method == http.MethodGet:
		list, err := DB.ListProjects()
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if list == nil {
			list = []models.Project{}
		}
		JSONOK(w, list)
	case path == "" && r.Method == http.MethodPost:
		var p models.Project
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			JSONError(w, "invalid body", http.StatusBadRequest)
			return
		}
		if p.Name == "" {
			JSONError(w, "name required", http.StatusBadRequest)
			return
		}
		if err := DB.CreateProject(&p); err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, p)
	case path != "" && r.Method == http.MethodGet:
		id, err := strconv.ParseInt(path, 10, 64)
		if err != nil {
			JSONError(w, "invalid id", http.StatusBadRequest)
			return
		}
		p, err := DB.GetProject(id)
		if err != nil {
			JSONError(w, err.Error(), http.StatusNotFound)
			return
		}
		tasks, _ := DB.ListProjectTasks(id)
		if tasks == nil {
			tasks = []models.Task{}
		}
		JSONOK(w, map[string]any{"project": p, "tasks": tasks})
	default:
		http.NotFound(w, r)
	}
}

func KanbanRouter(w http.ResponseWriter, r *http.Request) {
	switch {
	case r.Method == http.MethodGet:
		pid, _ := strconv.ParseInt(r.URL.Query().Get("project_id"), 10, 64)
		cols, err := DB.Kanban(pid)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, cols)
	case r.Method == http.MethodPost && strings.HasSuffix(r.URL.Path, "/reorder"):
		var req models.KanbanReorderRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil || len(req.Updates) == 0 {
			JSONError(w, "updates required", http.StatusBadRequest)
			return
		}
		if err := DB.ReorderKanban(req.Updates); err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		pid, _ := strconv.ParseInt(r.URL.Query().Get("project_id"), 10, 64)
		cols, _ := DB.Kanban(pid)
		JSONOK(w, cols)
	default:
		http.NotFound(w, r)
	}
}

func TimeEntriesRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/time-entries")
	path = strings.Trim(path, "/")

	switch {
	case path == "active" && r.Method == http.MethodGet:
		e, err := DB.GetActiveTimer()
		if err != nil {
			JSONOK(w, nil)
			return
		}
		JSONOK(w, e)
	case path == "stats" && r.Method == http.MethodGet:
		date := r.URL.Query().Get("date")
		if date == "" {
			date = time.Now().Format("2006-01-02")
		}
		st, err := DB.TimeStats(date)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, st)
	case path == "start" && r.Method == http.MethodPost:
		var req struct {
			TaskID int64 `json:"taskId"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			JSONError(w, "invalid body", http.StatusBadRequest)
			return
		}
		e, err := DB.StartTimer(req.TaskID)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, e)
	case strings.HasSuffix(path, "/pause") && r.Method == http.MethodPost:
		id, _ := strconv.ParseInt(strings.TrimSuffix(path, "/pause"), 10, 64)
		e, err := DB.PauseTimer(id)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, e)
	case strings.HasSuffix(path, "/resume") && r.Method == http.MethodPost:
		id, _ := strconv.ParseInt(strings.TrimSuffix(path, "/resume"), 10, 64)
		e, err := DB.ResumeTimer(id)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, e)
	case strings.HasSuffix(path, "/stop") && r.Method == http.MethodPost:
		idStr := strings.TrimSuffix(path, "/stop")
		id, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			JSONError(w, "invalid id", http.StatusBadRequest)
			return
		}
		e, err := DB.StopTimer(id)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, e)
	default:
		http.NotFound(w, r)
	}
}
