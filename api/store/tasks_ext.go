package store

import (
	"fmt"

	"github.com/oak899/bestme/api/models"
)

func (s *Store) ListSubtasks(parentID int64) ([]models.Task, error) {
	rows, err := s.db.Query(taskSelectSQL+` WHERE parent_id = ? ORDER BY sort_order, created_at`, parentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTasks(rows)
}

func (s *Store) ListTasksFiltered(date, category, status string, projectID, parentID int64) ([]models.Task, error) {
	q := taskSelectSQL + ` WHERE 1=1`
	args := []any{}
	if date != "" {
		q += ` AND date = ?`
		args = append(args, date)
	}
	if category != "" {
		q += ` AND category = ?`
		args = append(args, category)
	}
	if status != "" {
		q += ` AND status = ?`
		args = append(args, status)
	}
	if projectID > 0 {
		q += ` AND project_id = ?`
		args = append(args, projectID)
	}
	if parentID > 0 {
		q += ` AND parent_id = ?`
		args = append(args, parentID)
	} else if parentID == 0 && projectID == 0 {
		q += ` AND (parent_id IS NULL OR parent_id = 0)`
	}
	q += ` ORDER BY sort_order ASC, created_at ASC`
	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTasks(rows)
}

func (s *Store) UpdateTask(t *models.Task) (*models.Task, error) {
	old, _ := s.GetTask(t.ID)
	now := nowRFC()
	status := t.Status
	if status == "" {
		status = models.StatusTodo
	}
	var completedAt any
	if status == models.StatusDone {
		completedAt = now
	}
	res, err := s.db.Exec(`
		UPDATE tasks SET title=?, description=?, category=?, date=?, status=?, priority=?,
		project_id=?, parent_id=?, due_date=?, estimate_minutes=?, actual_minutes=?, tags=?,
		sort_order=?, needs_verification=?, updated_at=?, completed_at=COALESCE(?, completed_at)
		WHERE id=?`,
		t.Title, t.Description, t.Category, t.Date, status, t.Priority,
		nullIntPtr(t.ProjectID), nullIntPtr(t.ParentID), nullStr(t.DueDate),
		t.EstimateMinutes, t.ActualMinutes, tagsJSON(t.Tags), t.SortOrder,
		boolInt(t.NeedsVerification), now, completedAt, t.ID,
	)
	if err != nil {
		return nil, err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return nil, fmt.Errorf("task not found")
	}
	if old != nil && old.Status != status {
		_ = s.AddTaskHistory(t.ID, old.Status, status, "")
	}
	return s.GetTask(t.ID)
}

func (s *Store) UpdateTaskStatus(id int64, status string) (*models.Task, error) {
	old, err := s.GetTask(id)
	if err != nil {
		return nil, err
	}
	if old.Status == status {
		return old, nil
	}
	now := nowRFC()
	var completedAt any
	if status == models.StatusDone {
		completedAt = now
	} else {
		completedAt = nil
	}
	_, err = s.db.Exec(`UPDATE tasks SET status=?, updated_at=?, completed_at=? WHERE id=?`,
		status, now, completedAt, id)
	if err != nil {
		return nil, err
	}
	_ = s.AddTaskHistory(id, old.Status, status, "")
	return s.GetTask(id)
}

func (s *Store) AddTaskHistory(taskID int64, from, to, note string) error {
	_, err := s.db.Exec(`INSERT INTO task_history (task_id, from_status, to_status, note) VALUES (?,?,?,?)`,
		taskID, from, to, note)
	return err
}

func (s *Store) ListTaskHistory(taskID int64) ([]models.TaskHistory, error) {
	rows, err := s.db.Query(`SELECT id, task_id, from_status, to_status, changed_at, note
		FROM task_history WHERE task_id=? ORDER BY changed_at DESC`, taskID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.TaskHistory
	for rows.Next() {
		var h models.TaskHistory
		if err := rows.Scan(&h.ID, &h.TaskID, &h.FromStatus, &h.ToStatus, &h.ChangedAt, &h.Note); err != nil {
			return nil, err
		}
		out = append(out, h)
	}
	return out, rows.Err()
}

func (s *Store) AddTaskComment(taskID int64, body string) (*models.TaskComment, error) {
	now := nowRFC()
	res, err := s.db.Exec(`INSERT INTO task_comments (task_id, body, created_at) VALUES (?,?,?)`, taskID, body, now)
	if err != nil {
		return nil, err
	}
	id, _ := res.LastInsertId()
	return &models.TaskComment{ID: id, TaskID: taskID, Body: body, CreatedAt: now}, nil
}

func (s *Store) ListTaskComments(taskID int64) ([]models.TaskComment, error) {
	rows, err := s.db.Query(`SELECT id, task_id, body, created_at FROM task_comments WHERE task_id=? ORDER BY created_at ASC`, taskID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.TaskComment
	for rows.Next() {
		var c models.TaskComment
		if err := rows.Scan(&c.ID, &c.TaskID, &c.Body, &c.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func (s *Store) ReorderKanban(updates []models.KanbanReorderItem) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	now := nowRFC()
	for _, u := range updates {
		oldRow := tx.QueryRow(`SELECT status FROM tasks WHERE id=?`, u.ID)
		var oldStatus string
		if err := oldRow.Scan(&oldStatus); err != nil {
			return err
		}
		var completedAt any
		if u.Status == models.StatusDone {
			completedAt = now
		}
		_, err := tx.Exec(`UPDATE tasks SET status=?, sort_order=?, updated_at=?, completed_at=COALESCE(?, completed_at) WHERE id=?`,
			u.Status, u.SortOrder, now, completedAt, u.ID)
		if err != nil {
			return err
		}
		if oldStatus != u.Status {
			_, _ = tx.Exec(`INSERT INTO task_history (task_id, from_status, to_status) VALUES (?,?,?)`, u.ID, oldStatus, u.Status)
		}
	}
	return tx.Commit()
}

func nullIntPtr(v *int64) any {
	if v == nil || *v == 0 {
		return nil
	}
	return *v
}

func nullStr(s string) any {
	if s == "" {
		return nil
	}
	return s
}
