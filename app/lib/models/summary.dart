class DailySummary {
  DailySummary({
    required this.date,
    required this.total,
    required this.completed,
    required this.pending,
    required this.needsVerification,
    required this.byCategory,
    this.aiSummary,
  });

  final String date;
  final int total;
  final int completed;
  final int pending;
  final int needsVerification;
  final Map<String, CategoryStats> byCategory;
  final String? aiSummary;

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final raw = json['byCategory'] as Map<String, dynamic>? ?? {};
    final byCat = <String, CategoryStats>{};
    raw.forEach((k, v) {
      byCat[k] = CategoryStats.fromJson(v as Map<String, dynamic>);
    });
    return DailySummary(
      date: json['date'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      needsVerification: json['needsVerification'] as int? ?? 0,
      byCategory: byCat,
      aiSummary: json['aiSummary'] as String?,
    );
  }
}

class CategoryStats {
  CategoryStats({required this.total, required this.completed});

  final int total;
  final int completed;

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
    );
  }
}
