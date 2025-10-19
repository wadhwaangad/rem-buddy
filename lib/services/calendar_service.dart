import '../models/calendar_event.dart';
import '../models/calendar_item.dart';
import 'google_auth_service.dart';

class CalendarService {
  final GoogleAuthService _authService = GoogleAuthService();
  
  // Get today's events only
  Future<List<CalendarEventModel>> getTodayEvents() async {
    try {
      // Ensure user is signed in
      if (!_authService.isSignedIn) {
        print('⚠️ User not signed in. Attempting to sign in...');
        final signedIn = await _authService.signIn();
        if (!signedIn) {
          print('❌ Failed to sign in. Cannot fetch events.');
          return [];
        }
      }

      final calendarApi = await _authService.getCalendarApi();
      if (calendarApi == null) {
        print('⚠️ Could not get Calendar API. User might need to re-authenticate.');
        return [];
      }

      print('📅 Fetching today\'s events from Google Calendar...');
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final events = await calendarApi.events.list(
        'primary',
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      print('DEBUG: Raw events response:');
      print(events.items);

      if (events.items == null || events.items!.isEmpty) {
        print('0\ufe0f No events found for today.');
        return [];
      }

      print('0 Found ${events.items!.length} event(s) for today');
      for (var event in events.items!) {
        print('DEBUG: Event summary: ${event.summary}, start: ${event.start}, end: ${event.end}');
      }

      final List<CalendarEventModel> todayEvents = [];
      for (var event in events.items!) {
        final start = event.start?.dateTime ?? event.start?.date;
        final end = event.end?.dateTime ?? event.end?.date;
        if (start != null && end != null) {
          todayEvents.add(CalendarEventModel(
            id: event.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: event.summary ?? 'Untitled Event',
            description: event.description ?? '',
            startTime: start,
            endTime: end,
            location: event.location ?? '',
          ));
        } else {
          print('DEBUG: Skipping event with missing start/end: ${event.summary}');
        }
      }

      return todayEvents;
      
    } catch (e) {
      print('❌ Error fetching today\'s events: $e');
      print('   This might be due to authentication issues.');
      return [];
    }
  }

  // Get upcoming events (for backward compatibility, but limited to today)
  Future<List<CalendarEventModel>> getUpcomingEvents({int days = 1}) async {
    return getTodayEvents();
  }

  // Enhanced method to get all types of calendar data
  Future<List<CalendarItem>> getAllCalendarData() async {
    print('🔄 Fetching comprehensive calendar data...');
    
    List<CalendarItem> allItems = [];

    // Fetch Calendar Events
    try {
      final events = await getTodayEvents();
      for (var event in events) {
        allItems.add(CalendarItem.fromCalendarEvent(event));
      }
      print('📅 Added ${events.length} calendar events');
    } catch (e) {
      print('⚠️ Error fetching calendar events: $e');
    }

    // Fetch Google Tasks
    try {
      final tasks = await _getTodayTasks();
      allItems.addAll(tasks);
      print('✅ Added ${tasks.length} tasks');
    } catch (e) {
      print('⚠️ Error fetching tasks: $e');
    }

    // Fetch Calendar Reminders
    try {
      final reminders = await _getTodayReminders();
      allItems.addAll(reminders);
      print('⏰ Added ${reminders.length} reminders');
    } catch (e) {
      print('⚠️ Error fetching reminders: $e');
    }

    // Sort by priority and time
    allItems.sort((a, b) {
      // First sort by priority (high > medium > low)
      int priorityComparison = _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      
      // Then sort by time
      final aTime = a.startTime ?? a.dueDate ?? DateTime.now();
      final bTime = b.startTime ?? b.dueDate ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    print('🎯 Total items fetched: ${allItems.length}');
    return allItems;
  }

  // Private method to fetch Google Tasks
  Future<List<CalendarItem>> _getTodayTasks() async {
    try {
      if (!_authService.isSignedIn) {
        return [];
      }

      final tasksApi = await _authService.getTasksApi();
      if (tasksApi == null) {
        print('⚠️ Could not get Tasks API.');
        return [];
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(Duration(days: 1));

      // Get task lists
      final taskLists = await tasksApi.tasklists.list();
      if (taskLists.items == null || taskLists.items!.isEmpty) {
        return [];
      }

      List<CalendarItem> allTasks = [];

      // Fetch tasks from each list
      for (var taskList in taskLists.items!) {
        if (taskList.id == null) continue;
        
        try {
          final tasksResponse = await tasksApi.tasks.list(
            taskList.id!,
            dueMin: today.toUtc().toIso8601String(),
            dueMax: tomorrow.toUtc().toIso8601String(),
            showCompleted: false,
            showHidden: false,
          );

          if (tasksResponse.items != null) {
            for (var task in tasksResponse.items!) {
              if (task.title == null || task.title!.isEmpty) continue;
              
              DateTime? dueDate;
              if (task.due != null) {
                dueDate = DateTime.parse(task.due!);
              }

              allTasks.add(CalendarItem(
                id: task.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: task.title!,
                description: task.notes ?? '',
                dueDate: dueDate,
                type: CalendarItemType.task,
                isCompleted: task.status == 'completed',
                priority: _determinePriority(task.title!, task.notes ?? ''),
                source: 'google_tasks',
                tags: _extractTags(task.notes ?? ''),
              ));
            }
          }
        } catch (e) {
          print('⚠️ Error fetching tasks from list ${taskList.title}: $e');
        }
      }

      return allTasks;
    } catch (e) {
      print('❌ Error in _getTodayTasks: $e');
      return [];
    }
  }

  // Private method to fetch Calendar Reminders
  Future<List<CalendarItem>> _getTodayReminders() async {
    try {
      if (!_authService.isSignedIn) {
        return [];
      }

      final calendarApi = await _authService.getCalendarApi();
      if (calendarApi == null) {
        return [];
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Fetch events that are marked as reminders or have specific keywords
      final events = await calendarApi.events.list(
        'primary',
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        q: 'reminder OR remind OR TODO OR task',
      );

      List<CalendarItem> reminders = [];

      if (events.items != null) {
        for (var event in events.items!) {
          if (event.summary == null) continue;
          
          // Check if this looks like a reminder
          if (_isReminderEvent(event.summary!, event.description ?? '')) {
            final start = event.start?.dateTime ?? event.start?.date;
            
            reminders.add(CalendarItem(
              id: event.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: event.summary!,
              description: event.description ?? '',
              startTime: start,
              location: event.location ?? '',
              type: CalendarItemType.reminder,
              priority: _determinePriority(event.summary!, event.description ?? ''),
              source: 'google_calendar_reminders',
              tags: _extractTags(event.description ?? ''),
            ));
          }
        }
      }

      return reminders;
    } catch (e) {
      print('❌ Error in _getTodayReminders: $e');
      return [];
    }
  }

  // Helper methods
  bool _isReminderEvent(String title, String description) {
    final reminderKeywords = [
      'remind', 'reminder', 'todo', 'task', 'don\'t forget', 
      'remember', 'pick up', 'bring', 'take', 'buy', 'call'
    ];
    
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();
    
    return reminderKeywords.any((keyword) => 
        titleLower.contains(keyword) || descLower.contains(keyword));
  }

  String _determinePriority(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    
    // High priority keywords
    if (text.contains('urgent') || text.contains('asap') || 
        text.contains('important') || text.contains('critical') ||
        text.contains('deadline') || text.contains('must')) {
      return 'high';
    }
    
    // Low priority keywords
    if (text.contains('optional') || text.contains('maybe') || 
        text.contains('if time') || text.contains('low priority')) {
      return 'low';
    }
    
    return 'medium';
  }

  List<String> _extractTags(String text) {
    final tags = <String>[];
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    
    for (var match in matches) {
      if (match.group(1) != null) {
        tags.add(match.group(1)!);
      }
    }
    
    return tags;
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 2;
    }
  }
}
