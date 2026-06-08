# GrowthOS — 页面结构

## 导航架构

```
AppShell (BottomNav + Drawer)
├── Dashboard          /dashboard
├── Daily Plan         /daily-plan
├── Tasks              /tasks
├── Kanban             /kanban
├── Calendar           /calendar
├── Projects           /projects
│   └── ProjectDetail  /projects/:id
├── Reports            /reports
├── AI Coach           /ai-coach
└── Settings           /settings
```

## 页面明细

### Dashboard `/dashboard`

```
┌─────────────────────────────────┐
│ GrowthOS          [日期] [刷新] │
├─────────────────────────────────┤
│ 💬 每日激励语                    │
│ ┌─ 今日计划摘要 ─────────────┐  │
│ │ 重点: ...                   │  │
│ └─────────────────────────────┘  │
│ 今日工时  4h 32m   本周完成率 68% │
├─────────────────────────────────┤
│ ▶ 进行中 (2)                     │
│ ☐ 待办 (5)                       │
│ ✓ 已完成 (3)                     │
└─────────────────────────────────┘
```

### Daily Plan `/daily-plan`

- 日期选择器
- 重点目标（多行）
- 关联任务 chips
- 预计/实际工时
- 复盘 + 明日改进
- 操作：保存 | 复制昨日 | AI 生成

### Tasks `/tasks`

- 筛选：项目、优先级、状态、标签
- 列表 / 搜索
- FAB：新建任务
- 点击进入 TaskDetail

### Task Detail `/tasks/:id`

- 全字段编辑
- 子任务列表
- 评论线程
- 状态历史时间线
- 计时器控件

### Kanban `/kanban`

- 列：Backlog | Todo | In Progress | Blocked | Done
- 拖拽改状态（`table_calendar` + 自定义 board）
- 按项目筛选

### Calendar `/calendar`

- Tab：日 | 周 | 月
- 任务块 + Daily Plan 标记
- 点击日期 → Daily Plan

### Projects `/projects`

- 项目卡片（进度环）
- 新建项目
- ProjectDetail：目标、任务、工时、完成率

### Reports `/reports`

- Tab：日 | 周 | 月
- 图表区（fl_chart）
- 导出（V2）

### AI Coach `/ai-coach`

- 快捷入口：今日计划 / 复盘 / 明日 Top3 / 周报 / 语音转任务
- 对话式 UI（可选 V2）

### Settings `/settings`

- 目标工时、提醒、地点、工作日、主题、账号

## Flutter 路由表

| route | screen | file |
|-------|--------|------|
| `/` | DashboardScreen | `lib/features/dashboard/dashboard_screen.dart` |
| `/daily-plan` | DailyPlanScreen | `lib/features/daily_plan/daily_plan_screen.dart` |
| `/tasks` | TaskListScreen | `lib/features/tasks/task_list_screen.dart` |
| `/tasks/:id` | TaskDetailScreen | `lib/features/tasks/task_detail_screen.dart` |
| `/kanban` | KanbanScreen | `lib/features/kanban/kanban_screen.dart` |
| `/calendar` | CalendarScreen | `lib/features/calendar/calendar_screen.dart` |
| `/projects` | ProjectListScreen | `lib/features/projects/project_list_screen.dart` |
| `/projects/:id` | ProjectDetailScreen | `lib/features/projects/project_detail_screen.dart` |
| `/reports` | ReportsScreen | `lib/features/reports/reports_screen.dart` |
| `/ai-coach` | AiCoachScreen | `lib/features/ai_coach/ai_coach_screen.dart` |
| `/settings` | SettingsScreen | `lib/features/settings/settings_screen.dart` |
