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
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final String date;
  final String status;
  final bool needsVerification;
  final bool aiGenerated;

  bool get isDone => status == 'done';
  bool get isPending => status == 'pending';
  bool get needsVerify => status == 'needs_verification';

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'other',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      needsVerification: json['needsVerification'] as bool? ?? false,
      aiGenerated: json['aiGenerated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'date': date,
        'status': status,
        'needsVerification': needsVerification,
      };
}
