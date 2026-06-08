# GrowthOS — 代码结构

## Golang 后端

```
growthos/api/
├── cmd/server/main.go          # 入口：DB、router、静态 web
├── internal/
│   ├── config/config.go        # 环境变量
│   ├── middleware/
│   │   ├── cors.go
│   │   ├── jwt.go
│   │   └── logger.go
│   ├── models/                 # 领域模型 + JSON tags
│   │   ├── user.go
│   │   ├── task.go
│   │   ├── project.go
│   │   ├── daily_plan.go
│   │   └── time_entry.go
│   ├── store/
│   │   ├── store.go            # Open + migrate
│   │   ├── migrations/
│   │   │   └── 001_init.sql
│   │   ├── tasks.go
│   │   ├── projects.go
│   │   ├── daily_plans.go
│   │   ├── time_entries.go
│   │   └── reports.go
│   ├── handlers/
│   │   ├── auth.go
│   │   ├── dashboard.go
│   │   ├── tasks.go
│   │   ├── projects.go
│   │   ├── daily_plans.go
│   │   ├── kanban.go
│   │   ├── calendar.go
│   │   ├── time_entries.go
│   │   ├── reports.go
│   │   ├── reminders.go
│   │   └── ai.go
│   ├── ai/
│   │   ├── openai.go
│   │   ├── prompts.go
│   │   └── coach.go
│   └── router/router.go        # /api/v1 路由表
├── go.mod
└── go.sum
```

## Flutter 前端

```
growthos/app/
├── lib/
│   ├── main.dart
│   ├── app.dart                # MaterialApp + theme + router
│   ├── core/
│   │   ├── config/env.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── router/app_router.dart
│   │   └── api/
│   │       ├── api_client.dart
│   │       └── endpoints.dart
│   ├── features/
│   │   ├── shell/app_shell.dart
│   │   ├── dashboard/
│   │   ├── daily_plan/
│   │   ├── tasks/
│   │   ├── kanban/
│   │   ├── calendar/
│   │   ├── projects/
│   │   ├── reports/
│   │   ├── ai_coach/
│   │   └── settings/
│   ├── shared/
│   │   ├── models/             # 与 API 对齐的 Dart models
│   │   ├── providers/          # Riverpod/Provider
│   │   └── widgets/
│   └── l10n/                   # 中英 i18n (V1.1)
├── pubspec.yaml
└── test/
```

## 设计 Token

| Token | Light | Dark |
|-------|-------|------|
| primary | `#2563EB` | `#3B82F6` |
| surface | `#FFFFFF` | `#111827` |
| background | `#F8FAFC` | `#0F172A` |
| text | `#1E293B` | `#F1F5F9` |
| muted | `#94A3B8` | `#64748B` |
