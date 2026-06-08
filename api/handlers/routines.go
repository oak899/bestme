package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/oak899/growthos/api/models"
)

func RoutinesRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/routines")
	path = strings.Trim(path, "/")

	switch {
	case path == "" && r.Method == http.MethodGet:
		listRoutines(w, r)
	case path == "" && r.Method == http.MethodPost:
		createRoutine(w, r)
	case path != "" && r.Method == http.MethodDelete:
		deleteRoutine(w, r, path)
	default:
		http.NotFound(w, r)
	}
}

func listRoutines(w http.ResponseWriter, r *http.Request) {
	items, err := DB.ListRoutines(false)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if items == nil {
		items = []models.Routine{}
	}
	JSONOK(w, items)
}

func createRoutine(w http.ResponseWriter, r *http.Request) {
	var item models.Routine
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if item.Title == "" {
		JSONError(w, "title required", http.StatusBadRequest)
		return
	}
	if item.Category == "" {
		item.Category = models.CategoryLife
	}
	if err := DB.CreateRoutine(&item); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, item)
}

func deleteRoutine(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := DB.DeleteRoutine(id); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
