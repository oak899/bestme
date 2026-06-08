package store

import (
	"strings"
)

func (s *Store) migrateV2() error {
	alters := []string{
		`ALTER TABLE tasks ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium'`,
		`ALTER TABLE tasks ADD COLUMN project_id INTEGER`,
		`ALTER TABLE tasks ADD COLUMN parent_id INTEGER`,
		`ALTER TABLE tasks ADD COLUMN due_date TEXT`,
		`ALTER TABLE tasks ADD COLUMN estimate_minutes INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE tasks ADD COLUMN actual_minutes INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE tasks ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'`,
		`ALTER TABLE tasks ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE tasks ADD COLUMN updated_at TEXT`,
		`ALTER TABLE tasks ADD COLUMN completed_at TEXT`,
	}
	for _, q := range alters {
		_, _ = s.db.Exec(q)
	}

	_, err := s.db.Exec(strings.TrimSpace(`
CREATE TABLE IF NOT EXISTS projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  goal TEXT NOT NULL DEFAULT '',
  start_date TEXT,
  end_date TEXT,
  progress_pct REAL NOT NULL DEFAULT 0,
  color TEXT NOT NULL DEFAULT '#2563EB',
  archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS daily_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_date TEXT NOT NULL UNIQUE,
  focus_goals TEXT NOT NULL DEFAULT '',
  estimated_minutes INTEGER NOT NULL DEFAULT 0,
  actual_minutes INTEGER NOT NULL DEFAULT 0,
  review TEXT NOT NULL DEFAULT '',
  tomorrow_improve TEXT NOT NULL DEFAULT '',
  ai_generated INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS daily_plan_tasks (
  daily_plan_id INTEGER NOT NULL REFERENCES daily_plans(id),
  task_id INTEGER NOT NULL REFERENCES tasks(id),
  sort_order INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (daily_plan_id, task_id)
);

CREATE TABLE IF NOT EXISTS time_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL REFERENCES tasks(id),
  started_at TEXT NOT NULL,
  ended_at TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 0,
  paused_total_sec INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS task_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL REFERENCES tasks(id),
  from_status TEXT NOT NULL,
  to_status TEXT NOT NULL,
  changed_at TEXT NOT NULL DEFAULT (datetime('now')),
  note TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS task_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL REFERENCES tasks(id),
  body TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  daily_goal_minutes INTEGER NOT NULL DEFAULT 480,
  work_days TEXT NOT NULL DEFAULT '1,2,3,4,5',
  default_priority TEXT NOT NULL DEFAULT 'medium',
  theme TEXT NOT NULL DEFAULT 'system',
  growth_goal TEXT NOT NULL DEFAULT '',
  daily_plan_remind_at TEXT NOT NULL DEFAULT '09:00'
);

INSERT OR IGNORE INTO user_settings (id) VALUES (1);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_project ON tasks(project_id);

UPDATE tasks SET status = 'todo' WHERE status = 'pending';
UPDATE tasks SET status = 'blocked' WHERE status = 'needs_verification';
`))
	if err != nil {
		return err
	}
	return s.migrateV3()
}
