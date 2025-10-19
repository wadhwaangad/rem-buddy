import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to monitor Ring camera notifications
/// In production, this would listen to actual Ring app notifications
/// For demo purposes, includes simulation capability
class RingCameraService {
  final Random _random = Random();
  Timer? _simulationTimer;
  final StreamController<Map<String, dynamic>> _motionController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get motionDetected => _motionController.stream;

  /// Initialize the service to listen for Ring notifications
  /// In a real app, this would set up a notification listener
  Future<void> initialize() async {
    // In production, you would:
    // 1. Set up NotificationListenerService (Android)
    // 2. Request notification access permissions
    // 3. Filter for Ring app notifications (package: com.ringapp)
    // 4. Parse notification content for motion events
    
    print('RingCameraService: Initialized and listening for Ring notifications');
  }

  /// Start simulation mode for demo purposes
  /// This simulates receiving Ring notifications
  void startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      Duration(seconds: 30 + _random.nextInt(30)),
      (timer) {
        // 30% chance of detecting motion
        if (_random.nextDouble() < 0.3) {
          final motionData = {
            'timestamp': DateTime.now().toIso8601String(),
            'cameraName': 'Front Door',
            'motionType': 'person', // or 'package', 'vehicle', etc.
            'source': 'simulation',
          };
          _motionController.add(motionData);
          print('Ring Notification Received: Motion at ${motionData['cameraName']}');
        }
      },
    );
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
  }

  void dispose() {
    _simulationTimer?.cancel();
    _motionController.close();
  }

  /// Manually trigger a Ring notification (for testing)
  void triggerMotion({String? cameraName}) {
    final motionData = {
      'timestamp': DateTime.now().toIso8601String(),
      'cameraName': cameraName ?? 'Front Door',
      'motionType': 'person',
      'source': 'manual',
    };
    _motionController.add(motionData);
    print('Ring Notification Triggered: ${motionData['cameraName']}');
  }

  /// In production, this would be called when Ring notification is received
  /// Example notification format from Ring:
  /// Title: "Motion detected at Front Door"
  /// Body: "Someone is at your Front Door"
  void onRingNotificationReceived(String title, String body) {
    // Parse the notification
    final cameraName = _extractCameraName(title, body);
    final motionType = _detectMotionType(body);
    
    final motionData = {
      'timestamp': DateTime.now().toIso8601String(),
      'cameraName': cameraName,
      'motionType': motionType,
      'source': 'ring_app',
      'notificationTitle': title,
      'notificationBody': body,
    };
    
    _motionController.add(motionData);
    print('Ring Notification: $title');
  }

  String _extractCameraName(String title, String body) {
    // Common Ring notification patterns:
    // "Motion detected at Front Door"
    // "Someone is at your Front Door"
    
    final patterns = [
      RegExp(r'at (.+)$'),
      RegExp(r'your (.+)$'),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(title) ?? pattern.firstMatch(body);
      if (match != null && match.groupCount > 0) {
        return match.group(1) ?? 'Camera';
      }
    }
    
    return 'Front Door'; // Default
  }

  String _detectMotionType(String body) {
    final lowerBody = body.toLowerCase();
    
    if (lowerBody.contains('person') || lowerBody.contains('someone')) {
      return 'person';
    } else if (lowerBody.contains('package') || lowerBody.contains('delivery')) {
      return 'package';
    } else if (lowerBody.contains('vehicle') || lowerBody.contains('car')) {
      return 'vehicle';
    } else {
      return 'motion';
    }
  }
}

/// Extension: Android Notification Listener Implementation
/// 
/// To actually listen to Ring notifications on Android, you would:
/// 
/// 1. Add to AndroidManifest.xml:
/// ```xml
/// <service
///     android:name=".NotificationListener"
///     android:label="REM Buddy Notification Listener"
///     android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
///     <intent-filter>
///         <action android:name="android.service.notification.NotificationListenerService" />
///     </intent-filter>
/// </service>
/// ```
/// 
/// 2. Request permission:
/// ```dart
/// if (!await NotificationListenerService.isNotificationAccessGranted()) {
///   await NotificationListenerService.openNotificationAccessSettings();
/// }
/// ```
/// 
/// 3. Create native Android code (Kotlin):
/// ```kotlin
/// class NotificationListener : NotificationListenerService() {
///     override fun onNotificationPosted(sbn: StatusBarNotification) {
///         if (sbn.packageName == "com.ringapp") {
///             val title = sbn.notification.extras.getString("android.title")
///             val body = sbn.notification.extras.getString("android.text")
///             // Send to Flutter via MethodChannel
///         }
///     }
/// }
/// ```
/// 
/// 4. Set up MethodChannel in Flutter to receive events
