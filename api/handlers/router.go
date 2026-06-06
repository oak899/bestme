package handlers

import (
	"net/http"
	"strings"
)

func Router(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if path == "/api" || path == "/api/" {
		JSONOK(w, map[string]string{
			"name":    "BestMe API",
			"version": "1.0.0",
		})
		return
	}

	switch {
	case strings.HasPrefix(path, "/api/tasks"):
		TasksRouter(w, r)
	case strings.HasPrefix(path, "/api/routines"):
		RoutinesRouter(w, r)
	case strings.HasPrefix(path, "/api/events"):
		EventsRouter(w, r)
	case strings.HasPrefix(path, "/api/ai"):
		AIRouter(w, r)
	default:
		http.NotFound(w, r)
	}
}
