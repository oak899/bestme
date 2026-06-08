package store

import (
	"database/sql"
	"time"

	"github.com/oak899/bestme/api/models"
)

func (s *Store) StartTimer(taskID int64) (*models.TimeEntry, error) {
	now := nowRFC()
	res, err := s.db.Exec(`INSERT INTO time_entries (task_id, started_at) VALUES (?, ?)`, taskID, now)
	if err != nil {
		return nil, err
	}
	id, _ := res.LastInsertId()
	return &models.TimeEntry{ID: id, TaskID: taskID, StartedAt: now}, nil
}

func (s *Store) GetActiveTimer() (*models.TimeEntry, error) {
	row := s.db.QueryRow(`SELECT id, task_id, started_at, ended_at, duration_minutes, COALESCE(paused_total_sec,0), paused_at
		FROM time_entries WHERE ended_at IS NULL ORDER BY id DESC LIMIT 1`)
	e, err := scanTimeEntry(row)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return e, err
}

func (s *Store) PauseTimer(entryID int64) (*models.TimeEntry, error) {
	now := nowRFC()
	_, err := s.db.Exec(`UPDATE time_entries SET paused_at=? WHERE id=? AND ended_at IS NULL AND paused_at IS NULL`, now, entryID)
	if err != nil {
		return nil, err
	}
	return s.getTimeEntry(entryID)
}

func (s *Store) ResumeTimer(entryID int64) (*models.TimeEntry, error) {
	e, err := s.getTimeEntry(entryID)
	if err != nil {
		return nil, err
	}
	if e.PausedAt == "" {
		return e, nil
	}
	paused, _ := time.Parse(time.RFC3339, e.PausedAt)
	extra := int(time.Since(paused).Seconds())
	if extra < 0 {
		extra = 0
	}
	_, err = s.db.Exec(`UPDATE time_entries SET paused_total_sec=paused_total_sec+?, paused_at=NULL WHERE id=?`, extra, entryID)
	if err != nil {
		return nil, err
	}
	return s.getTimeEntry(entryID)
}

func (s *Store) StopTimer(entryID int64) (*models.TimeEntry, error) {
	e, err := s.getTimeEntry(entryID)
	if err != nil {
		return nil, err
	}
	if e.EndedAt != "" {
		return e, nil
	}
	if e.PausedAt != "" {
		e, _ = s.ResumeTimer(entryID)
	}
	end := time.Now().UTC()
	start, _ := time.Parse(time.RFC3339, e.StartedAt)
	elapsed := end.Sub(start).Seconds() - float64(e.PausedTotalSec)
	mins := int(elapsed / 60)
	if mins < 0 {
		mins = 0
	}
	endS := end.Format(time.RFC3339)
	_, err = s.db.Exec(`UPDATE time_entries SET ended_at=?, duration_minutes=?, paused_at=NULL WHERE id=?`, endS, mins, entryID)
	if err != nil {
		return nil, err
	}
	_, _ = s.db.Exec(`UPDATE tasks SET actual_minutes = actual_minutes + ? WHERE id = ?`, mins, e.TaskID)
	e.EndedAt = endS
	e.DurationMinutes = mins
	e.PausedAt = ""
	e.IsPaused = false
	return e, nil
}

func (s *Store) TimeStats(date string) (*models.TimeStats, error) {
	var dayMins int
	_ = s.db.QueryRow(`SELECT COALESCE(SUM(duration_minutes),0) FROM time_entries WHERE date(started_at)=? AND ended_at IS NOT NULL`, date).Scan(&dayMins)
	t, _ := time.Parse("2006-01-02", date)
	weekday := int(t.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	start := t.AddDate(0, 0, -(weekday - 1)).Format("2006-01-02")
	end := t.AddDate(0, 0, 7-weekday).Format("2006-01-02")
	var weekMins int
	_ = s.db.QueryRow(`SELECT COALESCE(SUM(duration_minutes),0) FROM time_entries WHERE date(started_at) BETWEEN ? AND ? AND ended_at IS NOT NULL`, start, end).Scan(&weekMins)
	settings, _ := s.GetSettings()
	goal := 480
	if settings != nil {
		goal = settings.DailyGoalMinutes
	}
	return &models.TimeStats{
		Date:           date,
		TotalMinutes:   dayMins,
		WeekTotalMins:  weekMins,
		DayGoalMinutes: goal,
	}, nil
}

func (s *Store) getTimeEntry(id int64) (*models.TimeEntry, error) {
	row := s.db.QueryRow(`SELECT id, task_id, started_at, ended_at, duration_minutes, COALESCE(paused_total_sec,0), paused_at FROM time_entries WHERE id=?`, id)
	return scanTimeEntry(row)
}

func scanTimeEntry(row *sql.Row) (*models.TimeEntry, error) {
	var e models.TimeEntry
	var ended, pausedAt sql.NullString
	if err := row.Scan(&e.ID, &e.TaskID, &e.StartedAt, &ended, &e.DurationMinutes, &e.PausedTotalSec, &pausedAt); err != nil {
		return nil, err
	}
	if ended.Valid {
		e.EndedAt = ended.String
	}
	if pausedAt.Valid && pausedAt.String != "" {
		e.PausedAt = pausedAt.String
		e.IsPaused = true
	}
	return &e, nil
}

type sqlStr struct{ s string }

func (n *sqlStr) Scan(v any) error {
	switch x := v.(type) {
	case string:
		n.s = x
	case []byte:
		n.s = string(x)
	case nil:
		n.s = ""
	}
	return nil
}
