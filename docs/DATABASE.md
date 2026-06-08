# GrowthOS — 数据库表结构

> 生产目标：**PostgreSQL 15+**  
> MVP 部署：SQLite（`modernc.org/sqlite`），类型与约束尽量兼容 PG 迁移。

## ER 概览

```
users ─┬─ daily_plans
       ├─ projects ── tasks ─┬─ task_comments
       │                     ├─ task_history
       │                     ├─ time_entries
       │                     └─ subtasks (self-ref parent_id)
       ├─ reminders
       ├─ user_settings
       └─ saved_locations
```

## 表定义

### users

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL / INTEGER PK | |
| email | TEXT UNIQUE NOT NULL | |
| password_hash | TEXT NOT NULL | bcrypt |
| display_name | TEXT | |
| created_at | TIMESTAMPTZ | |

### user_settings

| 列 | 类型 | 说明 |
|----|------|------|
| user_id | FK users | PK |
| daily_goal_minutes | INT DEFAULT 480 | 目标 8h |
| work_days | TEXT DEFAULT '1,2,3,4,5' | 周一=1 |
| default_priority | TEXT DEFAULT 'medium' | |
| theme | TEXT DEFAULT 'system' | light/dark/system |
| growth_goal | TEXT | 个人成长目标 |
| pomodoro_work_min | INT DEFAULT 25 | |
| pomodoro_break_min | INT DEFAULT 5 | |
| daily_plan_remind_at | TEXT | HH:MM |

### projects

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| user_id | FK | |
| name | TEXT NOT NULL | |
| goal | TEXT | 项目目标 |
| start_date | DATE | |
| end_date | DATE | |
| progress_pct | REAL DEFAULT 0 | 计算或缓存 |
| color | TEXT | UI 色 |
| archived | BOOL DEFAULT false | |
| created_at | TIMESTAMPTZ | |

### tasks

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| user_id | FK | |
| project_id | FK nullable | |
| parent_id | FK tasks nullable | 子任务 |
| title | TEXT NOT NULL | |
| description | TEXT | |
| priority | TEXT | high/medium/low |
| status | TEXT | backlog/todo/in_progress/blocked/done |
| due_date | DATE nullable | |
| scheduled_start | TIMESTAMPTZ | 日历时间块 |
| scheduled_end | TIMESTAMPTZ | |
| estimate_minutes | INT | 预计耗时 |
| actual_minutes | INT DEFAULT 0 | 累计实际 |
| tags | TEXT | JSON 数组字符串 |
| sort_order | INT DEFAULT 0 | Kanban 排序 |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |
| completed_at | TIMESTAMPTZ | |

### daily_plans

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| user_id | FK | |
| plan_date | DATE | UNIQUE(user_id, plan_date) |
| focus_goals | TEXT | 今日重点 |
| estimated_minutes | INT | |
| actual_minutes | INT | |
| review | TEXT | 复盘 |
| tomorrow_improve | TEXT | 明日改进 |
| ai_generated | BOOL | |
| created_at | TIMESTAMPTZ | |

### daily_plan_tasks

| 列 | 类型 | 说明 |
|----|------|------|
| daily_plan_id | FK | |
| task_id | FK | |
| sort_order | INT | |

### task_comments

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| task_id | FK | |
| user_id | FK | |
| body | TEXT | |
| created_at | TIMESTAMPTZ | |

### task_history

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| task_id | FK | |
| from_status | TEXT | |
| to_status | TEXT | |
| changed_at | TIMESTAMPTZ | |
| note | TEXT | |

### time_entries

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| user_id | FK | |
| task_id | FK | |
| started_at | TIMESTAMPTZ | |
| ended_at | TIMESTAMPTZ nullable | |
| duration_minutes | INT | 结束时计算 |
| paused_total_sec | INT DEFAULT 0 | |

### reminders

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGSERIAL PK | |
| user_id | FK | |
| task_id | FK nullable | |
| type | TEXT | task/daily_plan/pomodoro/overtime/geo |
| trigger_at | TIMESTAMPTZ nullable | |
| geo_lat/lng/radius | REAL | 地理提醒 |
| geo_place_name | TEXT | |
| geo_event | TEXT | enter/exit |
| enabled | BOOL | |
| payload | TEXT | JSON |

### saved_locations

| 列 | 类型 | 说明 |
|----|------|------|
| id | PK | |
| user_id | FK | |
| name | TEXT | 公司/家/咖啡店 |
| lat | REAL | |
| lng | REAL | |
| radius_m | INT DEFAULT 200 | |

### ai_logs (可选)

| 列 | 类型 | 说明 |
|----|------|------|
| id | PK | |
| user_id | FK | |
| kind | TEXT | plan/review/weekly/nl_task |
| input | TEXT | |
| output | TEXT | |
| created_at | TIMESTAMPTZ | |

## 索引

```sql
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_due ON tasks(user_id, due_date);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_time_entries_user_day ON time_entries(user_id, started_at);
CREATE INDEX idx_daily_plans_user_date ON daily_plans(user_id, plan_date);
```

## SQLite MVP 文件

`/opt/bestme/data/growthos.db`

迁移见 `api/store/migrations/001_init.sql`
