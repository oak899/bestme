package store

import "github.com/oak899/growthos/api/models"

func (s *Store) GetSettings() (*models.UserSettings, error) {
	var us models.UserSettings
	err := s.db.QueryRow(`SELECT daily_goal_minutes, work_days, default_priority, theme, growth_goal, daily_plan_remind_at
		FROM user_settings WHERE id=1`).Scan(
		&us.DailyGoalMinutes, &us.WorkDays, &us.DefaultPriority, &us.Theme, &us.GrowthGoal, &us.DailyPlanRemindAt,
	)
	if err != nil {
		return nil, err
	}
	return &us, nil
}

func (s *Store) UpdateSettings(us *models.UserSettings) (*models.UserSettings, error) {
	_, err := s.db.Exec(`UPDATE user_settings SET daily_goal_minutes=?, work_days=?, default_priority=?, theme=?, growth_goal=?, daily_plan_remind_at=? WHERE id=1`,
		us.DailyGoalMinutes, us.WorkDays, us.DefaultPriority, us.Theme, us.GrowthGoal, us.DailyPlanRemindAt,
	)
	if err != nil {
		return nil, err
	}
	return s.GetSettings()
}
