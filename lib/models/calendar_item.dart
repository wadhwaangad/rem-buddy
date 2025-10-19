import 'package:timezone/timezone.dart' as tz;

enum CalendarItemType {
  event,
  task,
  reminder,
  note,
}

class CalendarItem {
  final String id;
  final String title;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? dueDate;
  final String location;
  final CalendarItemType type;
  final bool isCompleted;
  final String priority; // 'high', 'medium', 'low'
  final List<String> tags;
  final String source; // 'google_calendar', 'google_tasks', 'google_keep', etc.

  CalendarItem({
    required this.id,
    required this.title,
    this.description = '',
    this.startTime,
    this.endTime,
    this.dueDate,
    this.location = '',
    required this.type,
    this.isCompleted = false,
    this.priority = 'medium',
    this.tags = const [],
    this.source = 'unknown',
  });

  // Convert from CalendarEventModel for backward compatibility
  factory CalendarItem.fromCalendarEvent(dynamic event) {
    if (event.runtimeType.toString().contains('CalendarEventModel')) {
      return CalendarItem(
        id: event.id,
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        location: event.location,
        type: CalendarItemType.event,
        source: 'google_calendar',
      );
    }
    throw ArgumentError('Invalid event type');
  }

  // For display purposes
  String get displayTime {
    final pstLocation = tz.getLocation('America/Los_Angeles');
    
    if (startTime != null && endTime != null) {
      final startTimePST = tz.TZDateTime.from(startTime!, pstLocation);
      final endTimePST = tz.TZDateTime.from(endTime!, pstLocation);
      
      final start = '${startTimePST.hour.toString().padLeft(2, '0')}:${startTimePST.minute.toString().padLeft(2, '0')}';
      final end = '${endTimePST.hour.toString().padLeft(2, '0')}:${endTimePST.minute.toString().padLeft(2, '0')}';
      return '$start - $end PST';
    } else if (dueDate != null) {
      final dueDatePST = tz.TZDateTime.from(dueDate!, pstLocation);
      return 'Due: ${dueDatePST.hour.toString().padLeft(2, '0')}:${dueDatePST.minute.toString().padLeft(2, '0')} PST';
    }
    return 'All Day';
  }

  String get typeIcon {
    switch (type) {
      case CalendarItemType.event:
        return '📅';
      case CalendarItemType.task:
        return '✅';
      case CalendarItemType.reminder:
        return '⏰';
      case CalendarItemType.note:
        return '📝';
    }
  }

  String get priorityIcon {
    switch (priority) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'CalendarItem(id: $id, title: $title, type: $type, source: $source)';
  }
}