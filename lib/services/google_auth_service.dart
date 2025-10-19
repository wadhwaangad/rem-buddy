import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarReadonlyScope,
      tasks.TasksApi.tasksReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  bool get isSignedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<bool> signIn() async {
    try {
      print('📱 Initiating Google Sign-In...');
      
      // Try to sign in silently first
      _currentUser = await _googleSignIn.signInSilently();
      
      if (_currentUser == null) {
        // If silent sign-in fails, prompt the user
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        print('✅ Signed in as: ${_currentUser!.email}');
        return true;
      } else {
        print('⚠️ User cancelled sign-in');
        return false;
      }
    } catch (e) {
      print('❌ Error signing in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  Future<calendar.CalendarApi?> getCalendarApi() async {
    try {
      if (_currentUser == null) {
        print('⚠️ No signed-in user. Attempting to sign in...');
        final success = await signIn();
        if (!success) {
          return null;
        }
      }

      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      
      return calendar.CalendarApi(authenticateClient);
    } catch (e) {
      print('❌ Error getting Calendar API: $e');
      return null;
    }
  }

  Future<tasks.TasksApi?> getTasksApi() async {
    try {
      if (_currentUser == null) {
        print('⚠️ No signed-in user. Attempting to sign in...');
        final success = await signIn();
        if (!success) {
          return null;
        }
      }

      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      
      return tasks.TasksApi(authenticateClient);
    } catch (e) {
      print('❌ Error getting Tasks API: $e');
      return null;
    }
  }

  // Check if user is already signed in (for app startup)
  Future<bool> checkSignInStatus() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser != null;
    } catch (e) {
      print('❌ Error checking sign-in status: $e');
      return false;
    }
  }
}

// Custom HTTP client for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
