class Routine {
  Routine({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.needsVerification = false,
    this.active = true,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final bool needsVerification;
  final bool active;

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'life',
      needsVerification: json['needsVerification'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'needsVerification': needsVerification,
      };
}
