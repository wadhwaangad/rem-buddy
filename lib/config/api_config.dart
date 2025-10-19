import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Keys and Configuration
/// 
/// Get it from: https://makersuite.google.com/app/apikey
class ApiConfig {
  // Get API key from .env file
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Set to false to use mock data instead of real API
  static const bool useRealGeminiApi = true;
  
  // Gemini model to use
  static const String geminiModel = 'gemini-2.5-flash';
}
