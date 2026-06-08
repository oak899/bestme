# GrowthOS

个人成长 + 工作计划 + 任务管理。在 GrowthOS 原有 **生活/工作/运动** 追踪与 AI 能力上，合并了 GrowthOS 功能：看板、每日计划、项目、仪表盘等。

产品名：**GrowthOS · 成长计划**（）

- **Flutter** — web & mobile client (calls REST API)
- **Go + SQLite** — tasks, routines, events on server (`/opt/bestme/data/bestme.db`)
- **AI** — daily plans, summaries, reminders via OpenAI

## Architecture

| Component | Where |
|-----------|--------|
| Flutter app | Browser / phone → `https://bestme.zfloo.com/api` |
| Go API + SQLite | `/opt/bestme` on `45.76.66.28` |

## Deploy to 45.76.66.28

Isolated from other projects (`vivid`, `iwell`, `reson`, `livekit`):

```bash
cd ~/zfloo/growthos
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

First-time on server:

```bash
ssh root@45.76.66.28
cp /opt/bestme/bestme.env.example /opt/bestme/bestme.env
chmod 600 /opt/bestme/bestme.env
# Add OPENAI_API_KEY=sk-...
systemctl restart bestme
```

Site: **https://bestme.zfloo.com** (Let's Encrypt TLS via certbot).

## Run Flutter (mobile)

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://bestme.zfloo.com/api
```

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/ai/plan` | Generate daily plan |
| POST | `/api/ai/summary` | AI recap (client sends tasks) |
| POST | `/api/ai/reminder` | AI event reminder |

## License

MIT
