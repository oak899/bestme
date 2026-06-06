class BestMeEvent {
  BestMeEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.remindDaysBefore = 1,
    this.notes,
  });

  final String id;
  final String title;
  final String type;
  final String date;
  final int remindDaysBefore;
  final String? notes;

  factory BestMeEvent.fromJson(Map<String, dynamic> json) {
    return BestMeEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'event',
      date: json['date'] as String? ?? '',
      remindDaysBefore: json['remindDaysBefore'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'date': date,
        'remindDaysBefore': remindDaysBefore,
        'notes': notes,
      };
}

class ReminderItem {
  ReminderItem({
    required this.title,
    required this.type,
    required this.date,
    required this.daysUntil,
    this.aiMessage,
  });

  final String title;
  final String type;
  final String date;
  final int daysUntil;
  final String? aiMessage;

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      date: json['date'] as String? ?? '',
      daysUntil: json['daysUntil'] as int? ?? 0,
      aiMessage: json['aiMessage'] as String?,
    );
  }
}
