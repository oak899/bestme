package handlers

import (
	"net/http"
	"strings"
)

func Router(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "/api" || path == "/api/" {
		JSONOK(w, map[string]string{
			"name":    "GrowthOS",
			"product": "GrowthOS",
			"version": "5.0.0",
			"storage": "sqlite",
		})
		return
	}

	switch {
	case strings.HasPrefix(path, "/api/auth"):
		AuthRouter(w, r)
	case strings.HasPrefix(path, "/api/tasks"):
		TasksRouter(w, r)
	case strings.HasPrefix(path, "/api/routines"):
		RoutinesRouter(w, r)
	case strings.HasPrefix(path, "/api/events"):
		EventsRouter(w, r)
	case strings.HasPrefix(path, "/api/ai"):
		AIRouter(w, r)
	case path == "/api/dashboard":
		DashboardRouter(w, r)
	case strings.HasPrefix(path, "/api/daily-plans"):
		DailyPlansRouter(w, r)
	case strings.HasPrefix(path, "/api/projects"):
		ProjectsRouter(w, r)
	case strings.HasPrefix(path, "/api/kanban"):
		KanbanRouter(w, r)
	case strings.HasPrefix(path, "/api/time-entries"):
		TimeEntriesRouter(w, r)
	case path == "/api/settings":
		SettingsRouter(w, r)
	case path == "/api/reports":
		ReportsRouter(w, r)
	default:
		http.NotFound(w, r)
	}
}
