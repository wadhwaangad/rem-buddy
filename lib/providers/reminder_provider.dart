import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_item.dart';
import '../models/calendar_event.dart';
import '../models/calendar_item.dart';
import '../services/calendar_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/google_auth_service.dart';
import 'dart:convert';

class ReminderProvider extends ChangeNotifier {
  final CalendarService _calendarService = CalendarService();
  final GeminiService _geminiService = GeminiService();
  final NotificationService _notificationService = NotificationService();
  final GoogleAuthService _authService = GoogleAuthService();

  List<ReminderItem> _reminders = [];
  List<CalendarEventModel> _todayEvents = [];
  List<CalendarItem> _allCalendarItems = [];
  bool _isLoading = false;
  bool _isFirstLaunch = true;
  int _reminderMinutesBefore = 30;

  List<ReminderItem> get reminders => _reminders;
  List<CalendarEventModel> get todayEvents => _todayEvents;
  List<CalendarItem> get allCalendarItems => _allCalendarItems;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;
  int get reminderMinutesBefore => _reminderMinutesBefore;
  bool get isAuthenticated => _authService.isSignedIn;

  ReminderProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPreferences();
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    
    // Initialize Gemini AI with API key
    _geminiService.initialize();
    
    // Check if user has completed onboarding AND is authenticated
    if (!_isFirstLaunch) {
      // Check authentication status
      final isAuthenticated = await _authService.checkSignInStatus();
      if (!isAuthenticated) {
        // User was onboarded but not authenticated, reset to first launch
        _isFirstLaunch = true;
        await _savePreferences();
        notifyListeners();
        return;
      }
      await fetchReminders();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    _reminderMinutesBefore = prefs.getInt('reminderMinutesBefore') ?? 30;
    
    final remindersJson = prefs.getString('reminders');
    if (remindersJson != null) {
      final List<dynamic> decoded = json.decode(remindersJson);
      _reminders = decoded.map((item) => ReminderItem.fromJson(item)).toList();
    }
    
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', _isFirstLaunch);
    await prefs.setInt('reminderMinutesBefore', _reminderMinutesBefore);
    
    final remindersJson = json.encode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString('reminders', remindersJson);
  }

  Future<void> completeOnboarding(int minutesBefore) async {
    _isFirstLaunch = false;
    _reminderMinutesBefore = minutesBefore;
    await _savePreferences();
    await fetchReminders();
    notifyListeners();
  }

  Future<void> fetchReminders() async {
    if (_isLoading) return; // Prevent multiple concurrent fetches
    
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch only today's events (for backward compatibility)
      final events = await _calendarService.getTodayEvents();
      _todayEvents = events;
      
      // Fetch comprehensive calendar data (events, tasks, reminders)
      final allItems = await _calendarService.getAllCalendarData();
      _allCalendarItems = allItems;
      
      final List<ReminderItem> newReminders = [];

      // Process traditional calendar events
      for (var event in events) {
        final items = await _geminiService.generateReminderItems(event);
        final reminder = ReminderItem(
          id: event.id,
          eventTitle: event.title,
          eventDescription: event.description,
          eventTime: event.startTime,
          itemsToRemember: items,
          category: _categorizeEvent(event.title),
        );
        newReminders.add(reminder);
        // Schedule notification
        await _notificationService.scheduleReminder(
          reminder,
          _reminderMinutesBefore,
        );
      }

      // Process tasks and other calendar items
      for (var item in allItems) {
        if (item.type != CalendarItemType.event) {
          // Create reminder items for tasks and other types
          final eventModel = CalendarEventModel(
            id: item.id,
            title: '${item.typeIcon} ${item.title}',
            description: item.description,
            startTime: item.startTime ?? item.dueDate ?? DateTime.now(),
            endTime: item.endTime ?? (item.dueDate?.add(Duration(hours: 1)) ?? DateTime.now().add(Duration(hours: 1))),
            location: item.location,
          );
          
          final items = await _geminiService.generateReminderItems(eventModel);
          final reminder = ReminderItem(
            id: item.id,
            eventTitle: '${item.typeIcon} ${item.title}',
            eventDescription: item.description,
            eventTime: item.startTime ?? item.dueDate ?? DateTime.now(),
            itemsToRemember: items,
            category: _categorizeCalendarItem(item),
          );
          newReminders.add(reminder);
          
          // Schedule notification for all items
          await _notificationService.scheduleReminder(
            reminder,
            _reminderMinutesBefore,
          );
        }
      }

      _reminders = newReminders;
      await _savePreferences();
      
      print('🎯 Successfully fetched ${_reminders.length} reminders from ${_allCalendarItems.length} calendar items');
    } catch (e) {
      debugPrint('Error fetching reminders: $e'); // Use debugPrint instead of print
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _categorizeEvent(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('shop') || lowerTitle.contains('grocery')) return 'Shopping';
    if (lowerTitle.contains('gym') || lowerTitle.contains('workout')) return 'Fitness';
    if (lowerTitle.contains('work') || lowerTitle.contains('meeting')) return 'Work';
    if (lowerTitle.contains('doctor') || lowerTitle.contains('hospital')) return 'Health';
    if (lowerTitle.contains('travel') || lowerTitle.contains('trip')) return 'Travel';
    if (lowerTitle.contains('dinner') || lowerTitle.contains('lunch')) return 'Dining';
    return 'Other';
  }
  
  String _categorizeCalendarItem(CalendarItem item) {
    switch (item.type) {
      case CalendarItemType.task:
        return 'Tasks';
      case CalendarItemType.reminder:
        return 'Reminders';
      case CalendarItemType.note:
        return 'Notes';
      default:
        return _categorizeEvent(item.title);
    }
  }

  void toggleReminderComplete(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: !_reminders[index].isCompleted,
      );
      _savePreferences();
      notifyListeners();
    }
  }

  void updateReminderTime(int minutes) {
    _reminderMinutesBefore = minutes;
    _savePreferences();
    notifyListeners();
  }

  // Method to reset onboarding (useful for debugging or re-authentication)
  Future<void> resetOnboarding() async {
    _isFirstLaunch = true;
    _reminders.clear();
    _todayEvents.clear();
    await _authService.signOut();
    await _savePreferences();
    notifyListeners();
  }
}
