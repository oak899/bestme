package handlers

import (
	"encoding/json"
	"net/http"
)

func SettingsRouter(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		s, err := DB.GetSettings()
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, s)
	case http.MethodPut, http.MethodPatch:
		var body struct {
			DailyGoalMinutes  int    `json:"dailyGoalMinutes"`
			WorkDays          string `json:"workDays"`
			DefaultPriority   string `json:"defaultPriority"`
			Theme             string `json:"theme"`
			GrowthGoal        string `json:"growthGoal"`
			DailyPlanRemindAt string `json:"dailyPlanRemindAt"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			JSONError(w, "invalid body", http.StatusBadRequest)
			return
		}
		cur, err := DB.GetSettings()
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if body.DailyGoalMinutes > 0 {
			cur.DailyGoalMinutes = body.DailyGoalMinutes
		}
		if body.WorkDays != "" {
			cur.WorkDays = body.WorkDays
		}
		if body.DefaultPriority != "" {
			cur.DefaultPriority = body.DefaultPriority
		}
		if body.Theme != "" {
			cur.Theme = body.Theme
		}
		if body.GrowthGoal != "" {
			cur.GrowthGoal = body.GrowthGoal
		}
		if body.DailyPlanRemindAt != "" {
			cur.DailyPlanRemindAt = body.DailyPlanRemindAt
		}
		updated, err := DB.UpdateSettings(cur)
		if err != nil {
			JSONError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		JSONOK(w, updated)
	default:
		http.NotFound(w, r)
	}
}
