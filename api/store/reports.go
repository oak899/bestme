package store

import (
	"time"

	"github.com/oak899/growthos/api/models"
)

func periodDays(period string) int {
	switch period {
	case "2week":
		return 14
	case "month":
		return 30
	case "year":
		return 365
	default:
		return 7
	}
}

func (s *Store) Reports(date, period string) (*models.ReportsData, error) {
	t, _ := time.Parse("2006-01-02", date)
	days := periodDays(period)
	out := &models.ReportsData{Date: date, Period: period, Days: days}
	out.WeekCompletionPct, _ = s.WeekCompletionPct(date)

	start := t.AddDate(0, 0, -(days - 1)).Format("2006-01-02")
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE due_date IS NOT NULL AND due_date < ? AND status != 'done'`, date).Scan(&out.OverdueCount)
	var highTotal, highDone int
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date BETWEEN ? AND ? AND priority='high'`, start, date).Scan(&highTotal)
	_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date BETWEEN ? AND ? AND priority='high' AND status='done'`, start, date).Scan(&highDone)
	if highTotal > 0 {
		out.HighPriorityCompletion = highDone * 100 / highTotal
	}

	for i := days - 1; i >= 0; i-- {
		d := t.AddDate(0, 0, -i).Format("2006-01-02")
		var total, done int
		_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date=?`, d).Scan(&total)
		_ = s.db.QueryRow(`SELECT COUNT(*) FROM tasks WHERE date=? AND status='done'`, d).Scan(&done)
		pct := 0
		if total > 0 {
			pct = done * 100 / total
		}
		out.DailyCompletion = append(out.DailyCompletion, models.DayCompletion{
			Date: d, Total: total, Completed: done, Pct: pct,
		})
	}

	_ = s.db.QueryRow(`SELECT COALESCE(SUM(duration_minutes),0) FROM time_entries WHERE ended_at IS NOT NULL AND date(started_at) BETWEEN ? AND ?`, start, date).Scan(&out.TotalWorkMinutes)

	hrows, _ := s.db.Query(`SELECT CAST(strftime('%H', started_at) AS INTEGER), COALESCE(SUM(duration_minutes),0)
		FROM time_entries WHERE ended_at IS NOT NULL AND date(started_at) BETWEEN ? AND ? GROUP BY 1 ORDER BY 1`, start, date)
	if hrows != nil {
		for hrows.Next() {
			var b models.HourBucket
			_ = hrows.Scan(&b.Hour, &b.Minutes)
			out.HourlyDistribution = append(out.HourlyDistribution, b)
		}
		hrows.Close()
	}

	rows, err := s.db.Query(`
		SELECT COALESCE(p.id, 0), COALESCE(p.name, '未分类'), COALESCE(SUM(te.duration_minutes), 0)
		FROM time_entries te
		JOIN tasks t ON t.id = te.task_id
		LEFT JOIN projects p ON p.id = t.project_id
		WHERE te.ended_at IS NOT NULL AND date(te.started_at) BETWEEN ? AND ?
		GROUP BY COALESCE(p.id, 0), COALESCE(p.name, '未分类')
		ORDER BY 3 DESC`, start, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var totalMins int
	var shares []models.ProjectShare
	for rows.Next() {
		var ps models.ProjectShare
		if err := rows.Scan(&ps.ProjectID, &ps.ProjectName, &ps.Minutes); err != nil {
			return nil, err
		}
		totalMins += ps.Minutes
		shares = append(shares, ps)
	}
	for i := range shares {
		if totalMins > 0 {
			shares[i].Pct = float64(shares[i].Minutes) * 100 / float64(totalMins)
		}
	}
	out.ProjectTimeShare = shares
	return out, nil
}
