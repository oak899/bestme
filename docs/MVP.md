# GrowthOS — MVP 第一版开发计划

**周期:** 4–6 周（1 人全栈）  
**MVP 目标:** 可用的「计划 + 任务 Kanban + 计时 + 基础报表 + AI 计划/复盘」

## 阶段划分

### Phase 0 — 基础架构（第 1 周）

- [x] 从 BestMe fork → GrowthOS 重命名
- [ ] Go 项目结构 + chi router + JWT 占位
- [ ] SQLite schema v1 迁移
- [ ] Flutter 主题 + 路由 + 9 个页面壳
- [ ] 部署 `bestme.zfloo.com`（或复用 bestme 子域过渡）

### Phase 1 — 任务核心（第 2 周）

- [ ] Task CRUD + 5 状态流转 + history
- [ ] Project CRUD
- [ ] Kanban 看板（拖拽）
- [ ] Task 列表筛选
- [ ] 客户端 ApiService + 本地 Hive 缓存

### Phase 2 — 计划与 Dashboard（第 3 周）

- [ ] Daily Plan CRUD + 复制昨日
- [ ] Dashboard 聚合 API
- [ ] 首页四象限任务 + 工时卡片
- [ ] AI：生成今日计划、NL→Task

### Phase 3 — 时间与报表（第 4 周）

- [ ] 计时器 start/pause/stop
- [ ] 日/周工时统计
- [ ] Reports：折线 + 饼图（fl_chart）
- [ ] AI 每日复盘

### Phase 4 — 打磨（第 5–6 周）

- [ ] 日历月视图（任务点 + plan）
- [ ] 设置页（目标工时、主题）
- [ ] 任务评论
- [ ] 提醒（本地 notification，任务 due）
- [ ] 登录注册
- [ ] PostgreSQL 迁移脚本（可选）

## MVP 不包含

- 地理围栏提醒
- Google/Apple Calendar 同步
- 子任务（可 V1.1）
- 多人协作

## 里程碑验收

| 里程碑 | 验收标准 |
|--------|----------|
| M1 | 能创建项目、任务，Kanban 拖拽改状态 |
| M2 | 能写 Daily Plan，Dashboard 数据正确 |
| M3 | 计时器记录工时，报表有图 |
| M4 | AI 生成计划并写入任务；复盘可用 |

## 技术债（MVP 后）

- 单用户 JWT 多设备同步
- PostgreSQL 切换
- 离线冲突合并
- E2E 测试
