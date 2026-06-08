package store

import (
	"database/sql"
	"time"

	"github.com/oak899/bestme/api/models"
)

var quotes = []string{
	"专注今日，复利成长。",
	"计划你的工作，执行你的计划。",
	"小步快跑，持续精进。",
	"完成比完美更重要。",
}

func (s *Store) Dashboard(date string) (*models.Dashboard, error) {
	tasks, err := s.ListTasks(date, "")
	if err != nil {
		return nil, err
	}
	d := &models.Dashboard{
		Date:  date,
		Quote: quotes[len(date)%len(quotes)],
	}
	for _, t := range tasks {
		switch t.Status {
		case models.StatusDone:
			d.Done = append(d.Done, t)
		case models.StatusInProgress:
			d.InProgress = append(d.InProgress, t)
		case models.StatusBacklog, models.StatusTodo, models.StatusPending, models.StatusNeedsVerification, models.StatusBlocked:
			d.Todo = append(d.Todo, t)
		default:
			d.Todo = append(d.Todo, t)
		}
	}
	d.TodayMinutes, _ = s.SumMinutesForDate(date)
	d.WeekCompletionPct, _ = s.WeekCompletionPct(date)
	d.DailyPlan, _ = s.GetDailyPlan(date)
	return d, nil
}

func (s *Store) SumMinutesForDate(date string) (int, error) {
	var n sql.NullInt64
	err := s.db.QueryRow(`
		SELECT COALESCE(SUM(duration_minutes), 0) FROM time_entries
		WHERE date(started_at) = ? AND ended_at IS NOT NULL`, date).Scan(&n)
	if err != nil {
		return 0, err
	}
	return int(n.Int64), nil
}

func (s *Store) WeekCompletionPct(date string) (int, error) {
	t, _ := time.Parse("2006-01-02", date)
	weekday := int(t.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	start := t.AddDate(0, 0, -(weekday - 1))
	end := start.AddDate(0, 0, 6)
	startS := start.Format("2006-01-02")
	endS := end.Format("2006-01-02")
	var total, done int
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date BETWEEN ? AND ?`, startS, endS).Scan(&total)
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date BETWEEN ? AND ? AND status = 'done'`, startS, endS).Scan(&done)
	if total == 0 {
		return 0, nil
	}
	return done * 100 / total, nil
}

func (s *Store) Kanban(projectID int64) ([]models.KanbanColumn, error) {
	type colDef struct {
		label    string
		statuses []string
	}
	cols := []colDef{
		{models.StatusBacklog, []string{models.StatusBacklog}},
		{models.StatusTodo, []string{models.StatusTodo, models.StatusPending}},
		{models.StatusInProgress, []string{models.StatusInProgress}},
		{models.StatusBlocked, []string{models.StatusBlocked, models.StatusNeedsVerification}},
		{models.StatusDone, []string{models.StatusDone}},
	}
	out := make([]models.KanbanColumn, 0, len(cols))
	for _, col := range cols {
		tasks := []models.Task{}
		for _, st := range col.statuses {
			q := taskSelectSQL + ` WHERE status = ?`
			args := []any{st}
			if projectID > 0 {
				q += ` AND project_id = ?`
				args = append(args, projectID)
			}
			q += ` ORDER BY sort_order, created_at`
			rows, err := s.db.Query(q, args...)
			if err != nil {
				return nil, err
			}
			part, err := scanTasks(rows)
			rows.Close()
			if err != nil {
				return nil, err
			}
			tasks = append(tasks, part...)
		}
		out = append(out, models.KanbanColumn{Status: col.label, Tasks: tasks})
	}
	return out, nil
}
