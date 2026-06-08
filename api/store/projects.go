package store

import (
	"github.com/oak899/growthos/api/models"
)

func (s *Store) ListProjects() ([]models.Project, error) {
	rows, err := s.db.Query(`
		SELECT p.id, p.name, p.goal, p.start_date, p.end_date, p.progress_pct, p.color, p.archived, p.created_at,
		       COALESCE((SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id), 0),
		       COALESCE((SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id AND t.status = 'done'), 0)
		FROM projects p WHERE p.archived = 0 ORDER BY p.created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.Project
	for rows.Next() {
		var p models.Project
		var archived int
		if err := rows.Scan(&p.ID, &p.Name, &p.Goal, &p.StartDate, &p.EndDate, &p.ProgressPct, &p.Color, &archived, &p.CreatedAt, &p.TaskTotal, &p.TaskDone); err != nil {
			return nil, err
		}
		p.Archived = archived == 1
		out = append(out, p)
	}
	return out, rows.Err()
}

func (s *Store) GetProject(id int64) (*models.Project, error) {
	row := s.db.QueryRow(`
		SELECT p.id, p.name, p.goal, p.start_date, p.end_date, p.progress_pct, p.color, p.archived, p.created_at,
		       COALESCE((SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id), 0),
		       COALESCE((SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id AND t.status = 'done'), 0),
		       COALESCE((SELECT SUM(te.duration_minutes) FROM time_entries te JOIN tasks t ON t.id = te.task_id
		                 WHERE t.project_id = p.id AND te.ended_at IS NOT NULL), 0)
		FROM projects p WHERE p.id = ?`, id)
	var p models.Project
	var archived int
	var minutes int
	if err := row.Scan(&p.ID, &p.Name, &p.Goal, &p.StartDate, &p.EndDate, &p.ProgressPct, &p.Color, &archived, &p.CreatedAt, &p.TaskTotal, &p.TaskDone, &minutes); err != nil {
		return nil, err
	}
	p.Archived = archived == 1
	p.TotalMinutes = minutes
	if p.TaskTotal > 0 {
		p.ProgressPct = float64(p.TaskDone) * 100 / float64(p.TaskTotal)
	}
	return &p, nil
}

func (s *Store) ListProjectTasks(projectID int64) ([]models.Task, error) {
	rows, err := s.db.Query(taskSelectSQL+` WHERE project_id = ? AND (parent_id IS NULL OR parent_id = 0) ORDER BY sort_order, created_at`, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTasks(rows)
}

func (s *Store) CreateProject(p *models.Project) error {
	res, err := s.db.Exec(
		`INSERT INTO projects (name, goal, start_date, end_date, color) VALUES (?, ?, ?, ?, ?)`,
		p.Name, p.Goal, p.StartDate, p.EndDate, p.Color,
	)
	if err != nil {
		return err
	}
	id, _ := res.LastInsertId()
	p.ID = id
	if p.Color == "" {
		p.Color = "#2563EB"
	}
	return nil
}
