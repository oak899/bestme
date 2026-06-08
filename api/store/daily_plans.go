package store

import (
	"database/sql"

	"github.com/oak899/bestme/api/models"
)

func (s *Store) GetDailyPlan(date string) (*models.DailyPlan, error) {
	row := s.db.QueryRow(`SELECT id, plan_date, focus_goals, estimated_minutes, actual_minutes, review, tomorrow_improve, ai_generated, created_at
		FROM daily_plans WHERE plan_date = ?`, date)
	var p models.DailyPlan
	var ai int
	err := row.Scan(&p.ID, &p.PlanDate, &p.FocusGoals, &p.EstimatedMinutes, &p.ActualMinutes, &p.Review, &p.TomorrowImprove, &ai, &p.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	p.AIGenerated = ai == 1
	return &p, nil
}

func (s *Store) UpsertDailyPlan(p *models.DailyPlan) error {
	existing, err := s.GetDailyPlan(p.PlanDate)
	if err != nil {
		return err
	}
	if existing == nil {
		res, err := s.db.Exec(
			`INSERT INTO daily_plans (plan_date, focus_goals, estimated_minutes, actual_minutes, review, tomorrow_improve, ai_generated)
			 VALUES (?, ?, ?, ?, ?, ?, ?)`,
			p.PlanDate, p.FocusGoals, p.EstimatedMinutes, p.ActualMinutes, p.Review, p.TomorrowImprove, boolInt(p.AIGenerated),
		)
		if err != nil {
			return err
		}
		id, _ := res.LastInsertId()
		p.ID = id
		return nil
	}
	_, err = s.db.Exec(
		`UPDATE daily_plans SET focus_goals=?, estimated_minutes=?, actual_minutes=?, review=?, tomorrow_improve=?, ai_generated=? WHERE plan_date=?`,
		p.FocusGoals, p.EstimatedMinutes, p.ActualMinutes, p.Review, p.TomorrowImprove, boolInt(p.AIGenerated), p.PlanDate,
	)
	p.ID = existing.ID
	return err
}

func (s *Store) CopyDailyPlan(fromDate, toDate string) (*models.DailyPlan, error) {
	src, err := s.GetDailyPlan(fromDate)
	if err != nil {
		return nil, err
	}
	if src == nil {
		return nil, nil
	}
	dst := *src
	dst.PlanDate = toDate
	dst.Review = ""
	dst.TomorrowImprove = ""
	dst.ID = 0
	if err := s.UpsertDailyPlan(&dst); err != nil {
		return nil, err
	}
	return &dst, nil
}
