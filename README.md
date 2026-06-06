# BestMe

AI-powered daily tracker for **life**, **work**, and **exercise**. Built with **Flutter** (mobile/web) and **Go** (Vercel serverless), backed by **MongoDB Atlas**.

## Features

- **Daily tasks** by category (life, work, exercise, other)
- **AI daily plan** — describe your goals; AI creates a structured task list
- **Task states** — pending, done, needs verification (mail, payments, etc.)
- **Daily summary** — stats by category + AI narrative recap
- **Routines** — create once, auto-repeat every day
- **Events & birthdays** — reminders with AI-generated messages

## Project structure

```
bestme/
├── api/          # Go API for Vercel serverless
├── app/          # Flutter client
├── vercel.json
└── .env.example
```

## Setup

### 1. MongoDB Atlas

1. Create a free cluster at [mongodb.com/atlas](https://www.mongodb.com/atlas)
2. Create database user and allow network access
3. Copy connection string → `MONGODB_URI`

### 2. OpenAI

Set `OPENAI_API_KEY` for AI plan, summary, and event reminders.

### 3. Deploy API to Vercel

```bash
cd ~/zfloo/bestme
vercel link
vercel env add MONGODB_URI
vercel env add OPENAI_API_KEY
vercel --prod
```

### 4. Run Flutter app

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://YOUR-PROJECT.vercel.app/api
```

For local API testing with `vercel dev`:

```bash
vercel dev
# In another terminal:
cd app && flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/tasks?date=YYYY-MM-DD` | List tasks |
| POST | `/api/tasks` | Create task |
| PATCH | `/api/tasks/:id/status` | Update status |
| POST | `/api/tasks/generate-routines` | Materialize today's routines |
| POST | `/api/ai/plan` | Generate AI daily plan |
| POST | `/api/ai/apply-plan` | Save AI plan as tasks |
| POST | `/api/ai/summary` | Daily summary + AI recap |
| GET/POST | `/api/routines` | Daily repeating routines |
| GET/POST | `/api/events` | Birthdays & events |
| GET | `/api/events/reminders` | Upcoming AI reminders |

## License

MIT
