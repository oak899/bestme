# GrowthOS — 开发任务清单（可直接开工）

## 后端 Go

- [ ] **G-01** 重命名 module `github.com/oak899/bestme/api`
- [ ] **G-02** 添加 `internal/router/router.go` chi 路由 `/api/v1`
- [ ] **G-03** 实现 `store/migrations/001_init.sql` 并执行 migrate
- [ ] **G-04** `handlers/auth` register/login JWT
- [ ] **G-05** `handlers/tasks` 全 CRUD + status + history
- [ ] **G-06** `handlers/projects` CRUD + 进度计算
- [ ] **G-07** `handlers/daily_plans` upsert + copy-yesterday
- [ ] **G-08** `handlers/dashboard` 聚合查询
- [ ] **G-09** `handlers/time_entries` 计时器 API
- [ ] **G-10** `handlers/reports` daily/weekly 统计 SQL
- [ ] **G-11** `handlers/kanban` reorder
- [ ] **G-12** `handlers/ai` 迁移 bestme AI + 新 prompt
- [ ] **G-13** 中间件：CORS、JWT、request log
- [ ] **G-14** `deploy/growthos.service` + nginx `bestme.zfloo.com`

## 前端 Flutter

- [ ] **F-01** 重命名 app → `growthos`，包名 `com.growthos.app`
- [ ] **F-02** `core/theme/app_theme.dart` 蓝白灰 + DarkMode
- [ ] **F-03** `core/router/app_router.dart` go_router 9 页
- [ ] **F-04** `core/api/api_client.dart` + interceptors
- [ ] **F-05** `features/dashboard` 首页 UI
- [ ] **F-06** `features/daily_plan` 表单 + API
- [ ] **F-07** `features/tasks` 列表 + 详情
- [ ] **F-08** `features/kanban` 拖拽 board（`flutter_boardview` 或自研）
- [ ] **F-09** `features/projects` 列表 + 详情
- [ ] **F-10** `features/calendar` `table_calendar`
- [ ] **F-11** `features/reports` `fl_chart`
- [ ] **F-12** `features/ai_coach` 对话/表单
- [ ] **F-13** `features/settings` + Hive 本地缓存
- [ ] **F-14** `shared/widgets` TaskTile, PriorityChip, StatusBadge
- [ ] **F-15** 计时器 Provider + 通知

## 数据库 / DevOps

- [ ] **D-01** SQLite 本地开发 `data/growthos.dev.db`
- [ ] **D-02** PostgreSQL docker-compose（本地 PG 测试）
- [ ] **D-03** 环境变量文档 `.env.example`
- [ ] **D-04** GitHub repo `oak899/bestme`

## 建议执行顺序（本周）

1. G-01 → G-03 → G-05 → G-07（数据层+任务+计划）
2. F-01 → F-03 → F-05 → F-06（壳+首页+计划）
3. G-08 + F-05 联调 Dashboard
4. G-12 + F-12 AI 计划
5. 部署 G-14
