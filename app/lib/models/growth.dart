import 'task.dart';

class DashboardData {
  DashboardData({
    required this.date,
    required this.quote,
    required this.todayMinutes,
    required this.weekCompletionPct,
    required this.inProgress,
    required this.todo,
    required this.done,
    this.dailyPlan,
  });

  final String date;
  final String quote;
  final int todayMinutes;
  final int weekCompletionPct;
  final List<Task> inProgress;
  final List<Task> todo;
  final List<Task> done;
  final DailyPlan? dailyPlan;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<Task> parseList(String key) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    }

    DailyPlan? plan;
    final p = json['dailyPlan'];
    if (p is Map<String, dynamic>) {
      plan = DailyPlan.fromJson(p);
    }

    return DashboardData(
      date: json['date'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      todayMinutes: json['todayMinutes'] as int? ?? 0,
      weekCompletionPct: json['weekCompletionPct'] as int? ?? 0,
      inProgress: parseList('inProgress'),
      todo: parseList('todo'),
      done: parseList('done'),
      dailyPlan: plan,
    );
  }
}

class DailyPlan {
  DailyPlan({
    this.id,
    required this.planDate,
    this.focusGoals = '',
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.review = '',
    this.tomorrowImprove = '',
    this.aiGenerated = false,
  });

  final int? id;
  final String planDate;
  final String focusGoals;
  final int estimatedMinutes;
  final int actualMinutes;
  final String review;
  final String tomorrowImprove;
  final bool aiGenerated;

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        id: json['id'] as int?,
        planDate: json['planDate'] as String? ?? '',
        focusGoals: json['focusGoals'] as String? ?? '',
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
        actualMinutes: json['actualMinutes'] as int? ?? 0,
        review: json['review'] as String? ?? '',
        tomorrowImprove: json['tomorrowImprove'] as String? ?? '',
        aiGenerated: json['aiGenerated'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'planDate': planDate,
        'focusGoals': focusGoals,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'review': review,
        'tomorrowImprove': tomorrowImprove,
      };
}

class Project {
  Project({
    required this.id,
    required this.name,
    this.goal = '',
    this.startDate = '',
    this.endDate = '',
    this.progressPct = 0,
    this.color = '#2563EB',
    this.taskTotal = 0,
    this.taskDone = 0,
    this.totalMinutes = 0,
  });

  final int id;
  final String name;
  final String goal;
  final String startDate;
  final String endDate;
  final double progressPct;
  final String color;
  final int taskTotal;
  final int taskDone;
  final int totalMinutes;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        goal: json['goal'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        progressPct: (json['progressPct'] as num?)?.toDouble() ?? 0,
        color: json['color'] as String? ?? '#2563EB',
        taskTotal: json['taskTotal'] as int? ?? 0,
        taskDone: json['taskDone'] as int? ?? 0,
        totalMinutes: json['totalMinutes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'goal': goal,
        'color': color,
        if (startDate.isNotEmpty) 'startDate': startDate,
        if (endDate.isNotEmpty) 'endDate': endDate,
      };
}

class ProjectDetail {
  ProjectDetail({required this.project, required this.tasks});
  final Project project;
  final List<Task> tasks;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as List? ?? [])
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProjectDetail(
      project: Project.fromJson(json['project'] as Map<String, dynamic>),
      tasks: tasks,
    );
  }
}

class KanbanColumn {
  KanbanColumn({required this.status, required this.tasks});

  final String status;
  final List<Task> tasks;

  factory KanbanColumn.fromJson(Map<String, dynamic> json) {
    final raw = json['tasks'];
    final tasks = raw is List
        ? raw.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList()
        : <Task>[];
    return KanbanColumn(status: json['status'] as String? ?? '', tasks: tasks);
  }
}

class UserSettings {
  UserSettings({
    this.dailyGoalMinutes = 480,
    this.workDays = '1,2,3,4,5',
    this.defaultPriority = 'medium',
    this.theme = 'system',
    this.growthGoal = '',
    this.dailyPlanRemindAt = '09:00',
  });

  final int dailyGoalMinutes;
  final String workDays;
  final String defaultPriority;
  final String theme;
  final String growthGoal;
  final String dailyPlanRemindAt;

  factory UserSettings.fromJson(Map<String, dynamic> j) => UserSettings(
        dailyGoalMinutes: j['dailyGoalMinutes'] as int? ?? 480,
        workDays: j['workDays'] as String? ?? '1,2,3,4,5',
        defaultPriority: j['defaultPriority'] as String? ?? 'medium',
        theme: j['theme'] as String? ?? 'system',
        growthGoal: j['growthGoal'] as String? ?? '',
        dailyPlanRemindAt: j['dailyPlanRemindAt'] as String? ?? '09:00',
      );

  Map<String, dynamic> toJson() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'workDays': workDays,
        'defaultPriority': defaultPriority,
        'theme': theme,
        'growthGoal': growthGoal,
        'dailyPlanRemindAt': dailyPlanRemindAt,
      };

  UserSettings copyWith({int? dailyGoalMinutes, String? theme, String? growthGoal, String? defaultPriority, String? dailyPlanRemindAt}) =>
      UserSettings(
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        workDays: workDays,
        defaultPriority: defaultPriority ?? this.defaultPriority,
        theme: theme ?? this.theme,
        growthGoal: growthGoal ?? this.growthGoal,
        dailyPlanRemindAt: dailyPlanRemindAt ?? this.dailyPlanRemindAt,
      );
}

class ReportsData {
  ReportsData({
    required this.date,
    required this.dailyCompletion,
    required this.projectTimeShare,
    this.weekCompletionPct = 0,
    this.period = 'week',
    this.highPriorityCompletionPct = 0,
    this.overdueCount = 0,
    this.totalWorkMinutes = 0,
    this.hourlyDistribution = const [],
  });
  final String date;
  final String period;
  final List<DayCompletion> dailyCompletion;
  final List<ProjectShare> projectTimeShare;
  final int weekCompletionPct;
  final int highPriorityCompletionPct;
  final int overdueCount;
  final int totalWorkMinutes;
  final List<HourBucket> hourlyDistribution;

  factory ReportsData.fromJson(Map<String, dynamic> j) => ReportsData(
        date: j['date'] as String? ?? '',
        period: j['period'] as String? ?? 'week',
        weekCompletionPct: j['weekCompletionPct'] as int? ?? 0,
        highPriorityCompletionPct: j['highPriorityCompletionPct'] as int? ?? 0,
        overdueCount: j['overdueCount'] as int? ?? 0,
        totalWorkMinutes: j['totalWorkMinutes'] as int? ?? 0,
        dailyCompletion: _list(j['dailyCompletion'], DayCompletion.fromJson),
        projectTimeShare: _list(j['projectTimeShare'], ProjectShare.fromJson),
        hourlyDistribution: _list(j['hourlyDistribution'], HourBucket.fromJson),
      );
}

class HourBucket {
  HourBucket({required this.hour, required this.minutes});
  final int hour;
  final int minutes;
  factory HourBucket.fromJson(Map<String, dynamic> j) =>
      HourBucket(hour: j['hour'] as int? ?? 0, minutes: j['minutes'] as int? ?? 0);
}

class DayCompletion {
  DayCompletion({required this.date, required this.total, required this.completed, required this.pct});
  final String date;
  final int total;
  final int completed;
  final int pct;
  factory DayCompletion.fromJson(Map<String, dynamic> j) => DayCompletion(
        date: j['date'] as String? ?? '',
        total: j['total'] as int? ?? 0,
        completed: j['completed'] as int? ?? 0,
        pct: j['pct'] as int? ?? 0,
      );
}

class ProjectShare {
  ProjectShare({required this.projectId, required this.projectName, required this.minutes, required this.pct});
  final int projectId;
  final String projectName;
  final int minutes;
  final double pct;
  factory ProjectShare.fromJson(Map<String, dynamic> j) => ProjectShare(
        projectId: j['projectId'] as int? ?? 0,
        projectName: j['projectName'] as String? ?? '',
        minutes: j['minutes'] as int? ?? 0,
        pct: (j['pct'] as num?)?.toDouble() ?? 0,
      );
}

class TimeStats {
  TimeStats({required this.totalMinutes, required this.weekTotalMinutes, required this.dayGoalMinutes});
  final int totalMinutes;
  final int weekTotalMinutes;
  final int dayGoalMinutes;
  factory TimeStats.fromJson(Map<String, dynamic> j) => TimeStats(
        totalMinutes: j['totalMinutes'] as int? ?? 0,
        weekTotalMinutes: j['weekTotalMinutes'] as int? ?? 0,
        dayGoalMinutes: j['dayGoalMinutes'] as int? ?? 480,
      );
}

class TimeEntry {
  TimeEntry({required this.id, required this.taskId, this.isPaused = false, this.durationMinutes = 0});
  final int id;
  final int taskId;
  final bool isPaused;
  final int durationMinutes;
  factory TimeEntry.fromJson(Map<String, dynamic> j) => TimeEntry(
        id: j['id'] as int? ?? 0,
        taskId: j['taskId'] as int? ?? 0,
        isPaused: j['isPaused'] as bool? ?? false,
        durationMinutes: j['durationMinutes'] as int? ?? 0,
      );
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
  if (raw is! List) return [];
  return raw.map((e) => f(e as Map<String, dynamic>)).toList();
}
