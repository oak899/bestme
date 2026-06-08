# GrowthOS — REST API 设计

**Base URL:** `https://bestme.zfloo.com/api/v1`  
**Auth:** `Authorization: Bearer <jwt>`（MVP 可用 `X-User-Id: 1` 占位）

## 通用

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| POST | `/auth/register` | 注册 |
| POST | `/auth/login` | 登录 → JWT |
| GET | `/me` | 当前用户 + settings |

## Dashboard

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/dashboard?date=YYYY-MM-DD` | 聚合：计划、任务分组、今日工时、周完成率、激励语 |

## Daily Plan

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/daily-plans?date=` | 获取某日计划 |
| POST | `/daily-plans` | 创建/更新（upsert） |
| POST | `/daily-plans/copy-yesterday` | `{ "date": "..." }` |
| POST | `/daily-plans/:id/tasks` | 关联任务 |

## Tasks

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/tasks` | 筛选：status, project_id, priority, due_before, q |
| POST | `/tasks` | 创建 |
| GET | `/tasks/:id` | 详情含子任务、评论 |
| PATCH | `/tasks/:id` | 更新字段 |
| PATCH | `/tasks/:id/status` | `{ "status": "in_progress" }` → 写 history |
| DELETE | `/tasks/:id` | 软删或硬删 |
| POST | `/tasks/:id/comments` | 评论 |
| GET | `/tasks/:id/history` | 状态历史 |

## Kanban

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/kanban?project_id=` | 按列分组任务 |
| PATCH | `/kanban/reorder` | `{ task_id, status, sort_order }` |

## Projects

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/projects` | 列表含进度 |
| POST | `/projects` | 创建 |
| GET | `/projects/:id` | 详情 + 统计 |
| PATCH | `/projects/:id` | 更新 |
| DELETE | `/projects/:id` | 归档 |

## Calendar

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/calendar?from=&to=` | 任务时间块 + daily_plans |

## Time Tracking

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/time-entries/start` | `{ task_id }` |
| POST | `/time-entries/:id/pause` | |
| POST | `/time-entries/:id/resume` | |
| POST | `/time-entries/:id/stop` | |
| GET | `/time-entries?from=&to=` | 列表 |

## Reports

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/reports/daily?date=` | 完成率、工时 |
| GET | `/reports/weekly?week=` | 趋势 |
| GET | `/reports/monthly?month=` | 月统计 |
| GET | `/reports/heatmap?from=&to=` | 工作时段 |

## Reminders

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/reminders` | |
| POST | `/reminders` | |
| PATCH | `/reminders/:id` | |
| DELETE | `/reminders/:id` | |

## AI Coach

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/ai/daily-plan` | 生成今日计划 |
| POST | `/ai/review` | 每日复盘 |
| POST | `/ai/procrastination` | 拖延分析 |
| POST | `/ai/tomorrow-top3` | 明日重点 |
| POST | `/ai/weekly-report` | 周报 |
| POST | `/ai/nl-to-task` | 自然语言 → task JSON |

## 响应格式

```json
{ "data": { ... }, "meta": { "page": 1 } }
```

错误：

```json
{ "error": { "code": "VALIDATION", "message": "..." } }
```
