class ReminderItem {
  final String id;
  final String eventTitle;
  final String eventDescription;
  final DateTime eventTime;
  final List<String> itemsToRemember;
  final String category;
  final bool isCompleted;

  ReminderItem({
    required this.id,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventTime,
    required this.itemsToRemember,
    required this.category,
    this.isCompleted = false,
  });

  ReminderItem copyWith({
    String? id,
    String? eventTitle,
    String? eventDescription,
    DateTime? eventTime,
    List<String>? itemsToRemember,
    String? category,
    bool? isCompleted,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventTime: eventTime ?? this.eventTime,
      itemsToRemember: itemsToRemember ?? this.itemsToRemember,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventTime': eventTime.toIso8601String(),
      'itemsToRemember': itemsToRemember,
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'],
      eventTitle: json['eventTitle'],
      eventDescription: json['eventDescription'],
      eventTime: DateTime.parse(json['eventTime']),
      itemsToRemember: List<String>.from(json['itemsToRemember']),
      category: json['category'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
