#!/usr/bin/env python3
"""Seed test data for BestMe API."""

import random
import requests
import sys
from datetime import datetime, timedelta

BASE_URL = "https://bestme.zfloo.com/api"
# BASE_URL = "http://localhost:8080/api"  # Uncomment for local dev

EMAIL = "test@growthos.com"
PASSWORD = "test123456"
NAME = "Test User"

CATEGORIES = ["life", "work", "exercise", "other"]
STATUSES = ["todo", "in_progress", "done", "blocked"]
PRIORITIES = ["low", "medium", "high"]
PROJECT_COLORS = ["#2563EB", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#06B6D4"]

token = None


def req(method, path, json_data=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    resp = requests.request(method, url, headers=headers, json=json_data, timeout=30)
    if resp.status_code >= 400:
        print(f"ERROR {resp.status_code} {path}: {resp.text[:200]}")
    return resp


def register_or_login():
    global token
    # Try login first
    resp = req("POST", "/auth/login", {"email": EMAIL, "password": PASSWORD})
    if resp.status_code == 200:
        token = resp.json()["token"]
        print(f"Logged in as {EMAIL}")
        return
    # Register if login fails
    resp = req("POST", "/auth/register", {"email": EMAIL, "password": PASSWORD, "name": NAME})
    if resp.status_code == 200:
        token = resp.json()["token"]
        print(f"Registered and logged in as {EMAIL}")
        return
    print("Auth failed:", resp.text)
    sys.exit(1)


def rand_date(offset_days=0):
    d = datetime.now() + timedelta(days=offset_days)
    return d.strftime("%Y-%m-%d")


def create_projects():
    projects = [
        {"name": "个人成长系统", "goal": "构建完整的个人成长追踪体系", "color": "#2563EB", "startDate": rand_date(-30)},
        {"name": "健身计划", "goal": "每周至少3次力量训练", "color": "#10B981", "startDate": rand_date(-14), "endDate": rand_date(60)},
        {"name": "读书笔记", "goal": "每月读完2本书并写笔记", "color": "#8B5CF6", "startDate": rand_date(-7)},
        {"name": " side project", "goal": "完成一个开源项目", "color": "#F59E0B", "startDate": rand_date(-60), "endDate": rand_date(90)},
    ]
    created = []
    for p in projects:
        resp = req("POST", "/projects", p)
        if resp.status_code == 200:
            created.append(resp.json())
            print(f"  Project: {p['name']}")
        else:
            print(f"  Failed project {p['name']}: {resp.text[:100]}")
    return created


def create_tasks(project_ids, count=40):
    task_templates = [
        ("阅读《深度工作》第一章", "work", "high"),
        ("完成 Flutter 状态管理重构", "work", "high"),
        ("健身房胸背训练", "exercise", "medium"),
        ("整理本周工作计划", "work", "medium"),
        ("冥想 15 分钟", "life", "low"),
        ("回复客户邮件", "work", "high"),
        ("学习 Dart 异步编程", "work", "medium"),
        ("准备周会汇报材料", "work", "high"),
        ("慢跑 5 公里", "exercise", "medium"),
        ("写技术博客", "work", "low"),
        ("复习英语单词", "life", "low"),
        ("优化数据库查询", "work", "high"),
        ("瑜伽拉伸", "exercise", "low"),
        ("更新简历", "life", "medium"),
        ("Code Review", "work", "medium"),
        ("设计新的 Logo", "work", "medium"),
        ("打卡背单词", "life", "low"),
        ("游泳", "exercise", "medium"),
        ("阅读《原子习惯》", "life", "low"),
        ("整理桌面文件", "life", "low"),
        ("部署生产环境", "work", "high"),
        ("修复登录 Bug", "work", "high"),
        ("制定下月预算", "life", "medium"),
        ("学习 Go 并发模式", "work", "medium"),
        ("平板支撑训练", "exercise", "low"),
    ]

    dates = [rand_date(i) for i in range(-5, 8)]
    created = 0
    for i in range(count):
        tpl = random.choice(task_templates)
        date = random.choice(dates)
        status = random.choice(STATUSES)
        # Weight toward more realistic distribution
        if random.random() < 0.3:
            status = "done"
        elif random.random() < 0.3:
            status = "todo"
        elif random.random() < 0.2:
            status = "in_progress"
        else:
            status = "blocked"

        payload = {
            "title": tpl[0],
            "description": f"这是任务 '{tpl[0]}' 的详细描述，创建于 {date}。",
            "category": tpl[1],
            "date": date,
            "status": status,
            "priority": tpl[2],
            "needsVerification": status == "blocked",
            "estimateMinutes": random.choice([15, 30, 45, 60, 90, 120]),
            "projectId": random.choice(project_ids) if random.random() < 0.6 else None,
            "tags": random.sample(["urgent", "deep-work", "quick-win", "planning"], k=random.randint(0, 2)),
        }
        resp = req("POST", "/tasks", payload)
        if resp.status_code == 200:
            created += 1
        else:
            print(f"  Failed task: {resp.text[:100]}")
    print(f"  Created {created}/{count} tasks")


def create_routines():
    routines = [
        {"title": "晨间冥想", "category": "life", "description": "每天早晨冥想10分钟", "needsVerification": False},
        {"title": "阅读30分钟", "category": "life", "description": "每天睡前阅读", "needsVerification": False},
        {"title": "健身", "category": "exercise", "description": "周一三五去健身房", "needsVerification": True},
        {"title": "写日报", "category": "work", "description": "下班前写当日工作总结", "needsVerification": False},
        {"title": "复盘", "category": "work", "description": "每周日复盘本周目标", "needsVerification": False},
    ]
    for r in routines:
        resp = req("POST", "/routines", r)
        if resp.status_code == 200:
            print(f"  Routine: {r['title']}")
        else:
            print(f"  Failed routine {r['title']}: {resp.text[:100]}")


def create_events():
    events = [
        {"title": "季度目标评审", "type": "milestone", "date": rand_date(7), "remindDaysBefore": 3, "notes": "回顾Q2目标完成情况"},
        {"title": "体检预约", "type": "event", "date": rand_date(14), "remindDaysBefore": 1},
        {"title": "Flutter 2.0 发布纪念", "type": "milestone", "date": rand_date(30), "remindDaysBefore": 7},
        {"title": "朋友生日", "type": "event", "date": rand_date(10), "remindDaysBefore": 1, "notes": "准备礼物"},
        {"title": "项目上线", "type": "milestone", "date": rand_date(21), "remindDaysBefore": 2, "notes": "最终验收测试"},
    ]
    for e in events:
        resp = req("POST", "/events", e)
        if resp.status_code == 200:
            print(f"  Event: {e['title']}")
        else:
            print(f"  Failed event {e['title']}: {resp.text[:100]}")


def create_daily_plans():
    focus_samples = [
        "完成 Flutter 性能优化",
        "阅读《深度工作》两章",
        "健身房力量训练",
        "整理技术文档",
        "学习新的设计模式",
        "完成周报和数据报表",
        "修复剩余 3 个 Bug",
    ]
    for offset in range(-3, 4):
        date = rand_date(offset)
        plan = {
            "planDate": date,
            "focusGoals": random.choice(focus_samples),
            "estimatedMinutes": random.randint(240, 480),
            "actualMinutes": random.randint(180, 520) if offset < 0 else 0,
            "review": "今日效率不错，完成了主要目标" if offset < 0 else "",
            "tomorrowImprove": "明天需要更早开始深度工作" if offset < 0 else "",
        }
        resp = req("POST", "/daily-plans", plan)
        if resp.status_code == 200:
            print(f"  DailyPlan: {date}")
        else:
            print(f"  Failed plan {date}: {resp.text[:100]}")


def save_settings():
    settings = {
        "dailyGoalMinutes": 480,
        "workDays": "1,2,3,4,5",
        "defaultPriority": "medium",
        "theme": "system",
        "growthGoal": "成为全栈工程师，精通 Flutter + Go，每周输出一篇技术博客",
        "dailyPlanRemindAt": "09:00",
    }
    resp = req("PUT", "/settings", settings)
    if resp.status_code == 200:
        print("  Settings saved")
    else:
        print(f"  Failed settings: {resp.text[:100]}")


def main():
    print("=" * 50)
    print("GrowthOS Test Data Seeder")
    print("=" * 50)
    print(f"API: {BASE_URL}")
    print()

    print("[1/6] Authenticating...")
    register_or_login()
    print()

    print("[2/6] Creating projects...")
    projects = create_projects()
    project_ids = [p["id"] for p in projects if "id" in p]
    print()

    print("[3/6] Creating tasks...")
    create_tasks(project_ids, count=40)
    print()

    print("[4/6] Creating routines...")
    create_routines()
    print()

    print("[5/6] Creating events...")
    create_events()
    print()

    print("[6/6] Creating daily plans...")
    create_daily_plans()
    print()

    print("[Bonus] Saving settings...")
    save_settings()
    print()

    print("=" * 50)
    print("Done! Login with:")
    print(f"  Email:    {EMAIL}")
    print(f"  Password: {PASSWORD}")
    print("=" * 50)


if __name__ == "__main__":
    main()
