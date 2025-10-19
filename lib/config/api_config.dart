/// API Keys and Configuration
/// 
/// Get it from: https://makersuite.google.com/app/apikey
class ApiConfig {
  // Get API key from environment variables
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty default - will use mock data if not set
  );
  
  // Set to false to use mock data instead of real API
  static const bool useRealGeminiApi = true;
  
  // Gemini model to use
  static const String geminiModel = 'gemini-2.5-flash';
}
