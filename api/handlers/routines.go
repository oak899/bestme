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
		http.Error(w, "not found", http.StatusNotFound)
	}
}

func listRoutines(w http.ResponseWriter, r *http.Request) {
	col, err := db.Collection("routines")
	if err != nil {
		JSONError(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	cur, err := col.Find(ctx, bson.M{}, options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}}))
	if err != nil {
		JSONError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cur.Close(ctx)

	var items []models.Routine
	if err := cur.All(ctx, &items); err != nil {
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
	item.Active = true
	item.CreatedAt = time.Now()

	col, err := db.Collection("routines")
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

func deleteRoutine(w http.ResponseWriter, r *http.Request, id string) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		JSONError(w, "invalid id", http.StatusBadRequest)
		return
	}

	col, err := db.Collection("routines")
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
