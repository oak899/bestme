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
		http.Error(w, "not found", http.StatusNotFound)
	}
}

func listEvents(w http.ResponseWriter, r *http.Request) {
	col, err := db.Collection("events")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	cur, err := col.Find(ctx, bson.M{}, options.Find().SetSort(bson.D{{Key: "date", Value: 1}}))
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var items []models.Event
	if err := cur.All(ctx, &items); err != nil {
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
	if item.RemindDaysBefore == 0 {
		item.RemindDaysBefore = 1
	}
	item.CreatedAt = time.Now()

	col, err := db.Collection("events")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	res, err := col.InsertOne(ctx, item)
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	item.ID = res.InsertedID.(primitive.ObjectID)
	JSONOK(w, item)
}

func deleteEvent(w http.ResponseWriter, r *http.Request, id string) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}

	col, err := db.Collection("events")
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

func eventReminders(w http.ResponseWriter, r *http.Request) {
	col, err := db.Collection("events")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()

	cur, err := col.Find(ctx, bson.M{})
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var events []models.Event
	if err := cur.All(ctx, &events); err != nil {
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
			EventID:   e.ID.Hex(),
			Title:     e.Title,
			Type:      e.Type,
			Date:      e.Date,
			DaysUntil: daysUntil,
		}
		msg, err := ai.EventReminder(e.Title, e.Type, e.Date, daysUntil)
		if err == nil {
			item.AIMessage = msg
		}
		reminders = append(reminders, item)
	}

	JSONOK(w, reminders)
}

func daysUntilEvent(today time.Time, dateStr string) int {
	eventDate := parseEventDate(today, dateStr)
	diff := eventDate.Sub(time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, today.Location()))
	return int(diff.Hours() / 24)
}

func parseEventDate(today time.Time, dateStr string) time.Time {
	layouts := []string{"2006-01-02", "01-02", "1-2"}
	for _, layout := range layouts {
		if t, err := time.Parse(layout, dateStr); err == nil {
			if layout == "2006-01-02" {
				return t
			}
			return time.Date(today.Year(), t.Month(), t.Day(), 0, 0, 0, 0, today.Location())
		}
	}
	return today
}
