package store

import (
	"database/sql"
	"encoding/json"
	"time"

	"github.com/oak899/growthos/api/models"
)

const taskSelectSQL = `SELECT id, title, description, category, date, status,
  COALESCE(priority,'medium'), project_id, parent_id, due_date,
  COALESCE(estimate_minutes,0), COALESCE(actual_minutes,0), COALESCE(tags,'[]'),
  COALESCE(sort_order,0), routine_id, ai_generated, needs_verification,
  created_at, updated_at, completed_at FROM tasks`

func scanTask(scanner interface {
	Scan(dest ...any) error
}) (*models.Task, error) {
	var t models.Task
	var routineID, projectID, parentID sql.NullInt64
	var dueDate, updatedAt, completedAt sql.NullString
	var tagsJSON string
	var aiGen, needsVer int
	if err := scanner.Scan(
		&t.ID, &t.Title, &t.Description, &t.Category, &t.Date, &t.Status,
		&t.Priority, &projectID, &parentID, &dueDate,
		&t.EstimateMinutes, &t.ActualMinutes, &tagsJSON, &t.SortOrder,
		&routineID, &aiGen, &needsVer, &t.CreatedAt, &updatedAt, &completedAt,
	); err != nil {
		return nil, err
	}
	if routineID.Valid {
		t.RoutineID = routineID.Int64
	}
	if projectID.Valid {
		v := projectID.Int64
		t.ProjectID = &v
	}
	if parentID.Valid {
		v := parentID.Int64
		t.ParentID = &v
	}
	if dueDate.Valid {
		t.DueDate = dueDate.String
	}
	if updatedAt.Valid {
		t.UpdatedAt = updatedAt.String
	}
	if completedAt.Valid {
		t.CompletedAt = completedAt.String
	}
	t.AIGenerated = aiGen == 1
	t.NeedsVerification = needsVer == 1
	_ = json.Unmarshal([]byte(tagsJSON), &t.Tags)
	if t.Tags == nil {
		t.Tags = []string{}
	}
	if t.Priority == "" {
		t.Priority = models.PriorityMedium
	}
	return &t, nil
}

func scanTasks(rows *sql.Rows) ([]models.Task, error) {
	var out []models.Task
	for rows.Next() {
		t, err := scanTask(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *t)
	}
	return out, rows.Err()
}

func tagsJSON(tags []string) string {
	if tags == nil {
		tags = []string{}
	}
	b, _ := json.Marshal(tags)
	return string(b)
}

func nowRFC() string {
	return time.Now().UTC().Format(time.RFC3339)
}
