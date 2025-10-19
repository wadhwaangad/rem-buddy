import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/calendar_event.dart';
import '../config/api_config.dart';

class GeminiService {
  late GenerativeModel _model;
  bool _isInitialized = false;

  void initialize() {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' || 
        ApiConfig.geminiApiKey.isEmpty ||
        !ApiConfig.useRealGeminiApi) {
      print('⚠️ Gemini API key not configured or disabled. Using mock data.');
      _isInitialized = false;
      return;
    }

    try {
      _model = GenerativeModel(
        model: ApiConfig.geminiModel,
        apiKey: ApiConfig.geminiApiKey,
      );
      _isInitialized = true;
      print('✅ Gemini API initialized successfully');
    } catch (e) {
      print('❌ Error initializing Gemini API: $e');
      print('   Falling back to mock data');
      _isInitialized = false;
    }
  }

  Future<List<String>> generateReminderItems(CalendarEventModel event) async {
    if (!_isInitialized) {
      // Return mock data if not initialized
      return _getMockReminders(event.title);
    }

    try {
      final prompt = '''
Based on this calendar event, generate a list of items the person should remember to take with them.
Be specific and practical. Return only the items as a comma-separated list.

Event Title: ${event.title}
Event Description: ${event.description}
Event Location: ${event.location}
Event Time: ${event.startTime}

Examples:
- For "Grocery Shopping": Wallet, Shopping bags, Shopping list, Phone, Keys, Loyalty cards
- For "Gym": Gym bag, Water bottle, Towel, Headphones, Phone, Keys, Workout clothes
- For "Work Meeting": Laptop, Phone, Charger, Notebook, Pen, ID badge, Keys
- For "Doctor Appointment": Insurance card, ID, Phone, Wallet, List of medications, Keys

Generate a similar list for the given event. Return ONLY the items separated by commas, no other text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        final items = response.text!
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        
        return items.isNotEmpty ? items : _getMockReminders(event.title);
      }
    } catch (e) {
      print('Error generating reminders: $e');
    }

    return _getMockReminders(event.title);
  }

  List<String> _getMockReminders(String eventTitle) {
    final title = eventTitle.toLowerCase();
    
    if (title.contains('shop') || title.contains('grocery')) {
      return ['Wallet', 'Shopping bags', 'Shopping list', 'Phone', 'Keys', 'Loyalty cards'];
    } else if (title.contains('gym') || title.contains('workout')) {
      return ['Gym bag', 'Water bottle', 'Towel', 'Headphones', 'Phone', 'Keys', 'Workout clothes'];
    } else if (title.contains('work') || title.contains('meeting') || title.contains('office')) {
      return ['Laptop', 'Phone', 'Charger', 'Notebook', 'Pen', 'ID badge', 'Keys', 'Wallet'];
    } else if (title.contains('doctor') || title.contains('hospital') || title.contains('clinic')) {
      return ['Insurance card', 'ID', 'Phone', 'Wallet', 'List of medications', 'Keys'];
    } else if (title.contains('travel') || title.contains('trip') || title.contains('vacation')) {
      return ['Passport', 'Tickets', 'Wallet', 'Phone', 'Charger', 'Keys', 'Luggage', 'Medications'];
    } else if (title.contains('school') || title.contains('class')) {
      return ['Backpack', 'Laptop', 'Notebooks', 'Pens', 'Phone', 'Student ID', 'Keys', 'Charger'];
    } else if (title.contains('dinner') || title.contains('lunch') || title.contains('restaurant')) {
      return ['Wallet', 'Phone', 'Keys', 'Reservation confirmation'];
    } else {
      return ['Phone', 'Wallet', 'Keys'];
    }
  }
}
