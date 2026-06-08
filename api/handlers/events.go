package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/oak899/bestme/api/ai"
	"github.com/oak899/bestme/api/models"
)

func EventsRouter(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/events")
	path = strings.Trim(path, "/")

	switch {
	case path == "" && r.Method == http.MethodGet:
		listEvents(w, r)
	case path == "" && r.Method == http.MethodPost:
		createEvent(w, r)
	case path == "reminders" && r.Method == http.MethodGet:
		eventReminders(w, r)
	case path != "" && r.Method == http.MethodDelete:
		deleteEvent(w, r, path)
	default:
		http.NotFound(w, r)
	}
}

func listEvents(w http.ResponseWriter, r *http.Request) {
	items, err := DB.ListEvents()
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if items == nil {
		items = []models.Event{}
	}
	JSONOK(w, items)
}

func createEvent(w http.ResponseWriter, r *http.Request) {
	var item models.Event
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		JSONError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if item.Title == "" || item.Date == "" {
		JSONError(w, "title and date required", http.StatusBadRequest)
		return
	}
	if item.Type == "" {
		item.Type = models.EventCustom
	}
	if err := DB.CreateEvent(&item); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	JSONOK(w, item)
}

func deleteEvent(w http.ResponseWriter, r *http.Request, idStr string) {
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := DB.DeleteEvent(id); err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func eventReminders(w http.ResponseWriter, r *http.Request) {
	events, err := DB.ListEvents()
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	today := time.Now()
	reminders := []models.ReminderItem{}
	for _, e := range events {
		daysUntil := daysUntilEvent(today, e.Date)
		if daysUntil < 0 || daysUntil > e.RemindDaysBefore {
			continue
		}
		item := models.ReminderItem{
			EventID:   e.ID,
			Title:     e.Title,
			Type:      e.Type,
			Date:      e.Date,
			DaysUntil: daysUntil,
		}
		if r.URL.Query().Get("ai") == "1" {
			if msg, err := ai.EventReminder(e.Title, e.Type, e.Date, daysUntil); err == nil {
				item.AIMessage = msg
			}
		}
		if item.AIMessage == "" {
			if daysUntil == 0 {
				item.AIMessage = "Today: " + e.Title
			} else {
				item.AIMessage = fmt.Sprintf("In %d day(s): %s", daysUntil, e.Title)
			}
		}
		reminders = append(reminders, item)
	}
	if reminders == nil {
		reminders = []models.ReminderItem{}
	}
	JSONOK(w, reminders)
}

func daysUntilEvent(today time.Time, dateStr string) int {
	eventDate := parseEventDate(today, dateStr)
	start := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, today.Location())
	return int(eventDate.Sub(start).Hours() / 24)
}

func parseEventDate(today time.Time, dateStr string) time.Time {
	if t, err := time.Parse("2006-01-02", dateStr); err == nil {
		return t
	}
	if t, err := time.Parse("01-02", dateStr); err == nil {
		return time.Date(today.Year(), t.Month(), t.Day(), 0, 0, 0, 0, today.Location())
	}
	return today
}
