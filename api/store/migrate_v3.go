package store

func (s *Store) migrateV3() error {
	_, err := s.db.Exec(`
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
`)
	if err != nil {
		return err
	}

	// Check if paused_at column exists before adding it
	var count int
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM pragma_table_info('time_entries') WHERE name = 'paused_at'`).Scan(&count)
	if count == 0 {
		_, err = s.db.Exec(`ALTER TABLE time_entries ADD COLUMN paused_at TEXT`)
	}
	return err
}
