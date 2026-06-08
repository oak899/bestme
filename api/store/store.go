package store

import (
	"database/sql"
	"time"

	"github.com/oak899/growthos/api/models"
	_ "modernc.org/sqlite"
)

type Store struct {
	db *sql.DB
}

func Open(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec(`PRAGMA foreign_keys = ON`); err != nil {
		return nil, err
	}
	if _, err := db.Exec(`PRAGMA busy_timeout = 10000`); err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	s := &Store{db: db}
	if err := s.migrate(); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Store) Close() error { return s.db.Close() }

func (s *Store) migrate() error {
	schema := `
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  routine_id INTEGER,
  ai_generated INTEGER NOT NULL DEFAULT 0,
  needs_verification INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tasks_date ON tasks(date);

CREATE TABLE IF NOT EXISTS routines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL,
  needs_verification INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  date TEXT NOT NULL,
  remind_days_before INTEGER NOT NULL DEFAULT 1,
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL
);
`
	if _, err := s.db.Exec(schema); err != nil {
		return err
	}
	return s.migrateV2()
}

func (s *Store) ListTasks(date, category string) ([]models.Task, error) {
	return s.ListTasksFiltered(date, category, "", 0, 0)
}

func (s *Store) CreateTask(t *models.Task) error {
	status := t.Status
	if status == "" {
		status = models.StatusTodo
	}
	if t.NeedsVerification && (status == models.StatusPending || status == models.StatusTodo) {
		status = models.StatusBlocked
	}
	if t.Priority == "" {
		t.Priority = models.PriorityMedium
	}
	now := nowRFC()
	res, err := s.db.Exec(
		`INSERT INTO tasks (title, description, category, date, status, priority, project_id, parent_id, due_date,
		 estimate_minutes, actual_minutes, tags, sort_order, routine_id, ai_generated, needs_verification, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		t.Title, t.Description, t.Category, t.Date, status, t.Priority,
		nullIntPtr(t.ProjectID), nullIntPtr(t.ParentID), nullStr(t.DueDate),
		t.EstimateMinutes, t.ActualMinutes, tagsJSON(t.Tags), t.SortOrder,
		nullInt(t.RoutineID), boolInt(t.AIGenerated), boolInt(t.NeedsVerification), now, now,
	)
	if err != nil {
		return err
	}
	id, _ := res.LastInsertId()
	t.ID = id
	t.Status = status
	t.CreatedAt = now
	t.UpdatedAt = now
	if t.Tags == nil {
		t.Tags = []string{}
	}
	_ = s.AddTaskHistory(id, "", status, "created")
	return nil
}

func (s *Store) GetTask(id int64) (*models.Task, error) {
	row := s.db.QueryRow(taskSelectSQL+` WHERE id = ?`, id)
	return scanTask(row)
}

func (s *Store) DeleteTask(id int64) error {
	_, err := s.db.Exec(`DELETE FROM tasks WHERE id = ?`, id)
	return err
}

func (s *Store) GenerateRoutineTasks(date string) ([]models.Task, error) {
	routines, err := s.ListRoutines(true)
	if err != nil {
		return nil, err
	}
	created := []models.Task{}
	for _, r := range routines {
		var n int
		if err := s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date = ? AND routine_id = ?`, date, r.ID).Scan(&n); err != nil {
			return nil, err
		}
		if n > 0 {
			continue
		}
		status := models.StatusTodo
		if r.NeedsVerification {
			status = models.StatusBlocked
		}
		t := models.Task{
			Title:             r.Title,
			Description:       r.Description,
			Category:          r.Category,
			Date:              date,
			Status:            status,
			RoutineID:         r.ID,
			NeedsVerification: r.NeedsVerification,
		}
		if err := s.CreateTask(&t); err != nil {
			return nil, err
		}
		created = append(created, t)
	}
	return created, nil
}

func (s *Store) ListRoutines(activeOnly bool) ([]models.Routine, error) {
	q := `SELECT id, title, description, category, needs_verification, active, created_at FROM routines`
	if activeOnly {
		q += ` WHERE active = 1`
	}
	q += ` ORDER BY created_at ASC`
	rows, err := s.db.Query(q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.Routine
	for rows.Next() {
		var r models.Routine
		var needsVer, active int
		if err := rows.Scan(&r.ID, &r.Title, &r.Description, &r.Category, &needsVer, &active, &r.CreatedAt); err != nil {
			return nil, err
		}
		r.NeedsVerification = needsVer == 1
		r.Active = active == 1
		out = append(out, r)
	}
	return out, rows.Err()
}

func (s *Store) CreateRoutine(r *models.Routine) error {
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.db.Exec(
		`INSERT INTO routines (title, description, category, needs_verification, active, created_at) VALUES (?, ?, ?, ?, 1, ?)`,
		r.Title, r.Description, r.Category, boolInt(r.NeedsVerification), now,
	)
	if err != nil {
		return err
	}
	id, _ := res.LastInsertId()
	r.ID = id
	r.Active = true
	r.CreatedAt = now
	return nil
}

func (s *Store) DeleteRoutine(id int64) error {
	_, err := s.db.Exec(`DELETE FROM routines WHERE id = ?`, id)
	return err
}

func (s *Store) ListEvents() ([]models.Event, error) {
	rows, err := s.db.Query(`SELECT id, title, type, date, remind_days_before, notes, created_at FROM events ORDER BY date ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.Event
	for rows.Next() {
		var e models.Event
		if err := rows.Scan(&e.ID, &e.Title, &e.Type, &e.Date, &e.RemindDaysBefore, &e.Notes, &e.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func (s *Store) CreateEvent(e *models.Event) error {
	if e.RemindDaysBefore == 0 {
		e.RemindDaysBefore = 1
	}
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.db.Exec(
		`INSERT INTO events (title, type, date, remind_days_before, notes, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		e.Title, e.Type, e.Date, e.RemindDaysBefore, e.Notes, now,
	)
	if err != nil {
		return err
	}
	id, _ := res.LastInsertId()
	e.ID = id
	e.CreatedAt = now
	return nil
}

func (s *Store) DeleteEvent(id int64) error {
	_, err := s.db.Exec(`DELETE FROM events WHERE id = ?`, id)
	return err
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

func nullInt(v int64) any {
	if v == 0 {
		return nil
	}
	return v
}
