class Task {
  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.status,
    this.description,
    this.needsVerification = false,
    this.aiGenerated = false,
    this.priority = 'medium',
    this.projectId,
    this.parentId,
    this.dueDate,
    this.estimateMinutes = 0,
    this.actualMinutes = 0,
    this.tags = const [],
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final String date;
  final String status;
  final bool needsVerification;
  final bool aiGenerated;
  final String priority;
  final int? projectId;
  final int? parentId;
  final String? dueDate;
  final int estimateMinutes;
  final int actualMinutes;
  final List<String> tags;
  final int sortOrder;

  bool get isDone => status == 'done';
  bool get isPending => status == 'pending' || status == 'todo' || status == 'backlog';
  bool get needsVerify => status == 'needs_verification' || status == 'blocked';
  bool get isInProgress => status == 'in_progress';

  factory Task.fromJson(Map<String, dynamic> json) {
    List<String> parseTags() {
      final t = json['tags'];
      if (t is List) return t.map((e) => e.toString()).toList();
      return [];
    }

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'other',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      needsVerification: json['needsVerification'] as bool? ?? false,
      aiGenerated: json['aiGenerated'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      projectId: json['projectId'] as int?,
      parentId: json['parentId'] as int?,
      dueDate: json['dueDate'] as String?,
      estimateMinutes: json['estimateMinutes'] as int? ?? 0,
      actualMinutes: json['actualMinutes'] as int? ?? 0,
      tags: parseTags(),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': int.tryParse(id),
        'title': title,
        'description': description ?? '',
        'category': category,
        'date': date,
        'status': status,
        'needsVerification': needsVerification,
        'priority': priority,
        if (projectId != null) 'projectId': projectId,
        if (parentId != null) 'parentId': parentId,
        if (dueDate != null && dueDate!.isNotEmpty) 'dueDate': dueDate,
        'estimateMinutes': estimateMinutes,
        'actualMinutes': actualMinutes,
        'tags': tags,
        'sortOrder': sortOrder,
      };

  Task copyWith({
    String? title,
    String? description,
    String? category,
    String? date,
    String? status,
    String? priority,
    int? projectId,
    String? dueDate,
    int? estimateMinutes,
    int? actualMinutes,
    List<String>? tags,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        date: date ?? this.date,
        status: status ?? this.status,
        needsVerification: needsVerification,
        aiGenerated: aiGenerated,
        priority: priority ?? this.priority,
        projectId: projectId ?? this.projectId,
        parentId: parentId,
        dueDate: dueDate ?? this.dueDate,
        estimateMinutes: estimateMinutes ?? this.estimateMinutes,
        actualMinutes: actualMinutes ?? this.actualMinutes,
        tags: tags ?? this.tags,
        sortOrder: sortOrder,
      );
}

class TaskHistory {
  TaskHistory({required this.id, required this.fromStatus, required this.toStatus, required this.changedAt, this.note});
  final int id;
  final String fromStatus;
  final String toStatus;
  final String changedAt;
  final String? note;

  factory TaskHistory.fromJson(Map<String, dynamic> j) => TaskHistory(
        id: j['id'] as int? ?? 0,
        fromStatus: j['fromStatus'] as String? ?? '',
        toStatus: j['toStatus'] as String? ?? '',
        changedAt: j['changedAt'] as String? ?? '',
        note: j['note'] as String?,
      );
}

class TaskComment {
  TaskComment({required this.id, required this.body, required this.createdAt});
  final int id;
  final String body;
  final String createdAt;

  factory TaskComment.fromJson(Map<String, dynamic> j) => TaskComment(
        id: j['id'] as int? ?? 0,
        body: j['body'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
      );
}
