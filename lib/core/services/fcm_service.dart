import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service.dart';

/// Top-level background message handler for FCM.
///
/// MUST be annotated with `@pragma('vm:entry-point')` to prevent tree-shaking
/// when executed in an isolated background Flutter engine.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('FCM Background Message Received: ${message.messageId}');
  } catch (e) {
    debugPrint('Error in FCM Background Handler: $e');
  }
}

/// Structured representation of a user's device registration for FCM push delivery.
class DeviceToken {
  final String deviceId;
  final String userId;
  final String organizationId;
  final String fcmToken;
  final String platform;
  final String role;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;

  const DeviceToken({
    required this.deviceId,
    required this.userId,
    required this.organizationId,
    required this.fcmToken,
    required this.platform,
    required this.role,
    this.enabled = true,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'organizationId': organizationId,
      'fcmToken': fcmToken,
      'platform': platform,
      'role': role,
      'enabled': enabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
  }

  factory DeviceToken.fromFirestore(Map<String, dynamic> data) {
    return DeviceToken(
      deviceId: data['deviceId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      organizationId: data['organizationId'] as String? ?? '',
      fcmToken: data['fcmToken'] as String? ?? '',
      platform: data['platform'] as String? ?? 'unknown',
      role: data['role'] as String? ?? 'guard',
      enabled: data['enabled'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Central service coordinating Firebase Cloud Messaging (FCM) push notifications,
/// Android notification channel setup, foreground system banners, token rotation,
/// and deep-link tap routing.
class FcmService {
  static const String channelId = 'cipher_x_alerts';
  static const String channelName = 'Cipher-X Alerts';
  static const String channelDescription =
      'Real-time operational security alerts and notifications.';

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  Function(Map<String, dynamic> data)? _onNotificationTapCallback;
  String? _currentUserId;
  String? _currentDeviceId;

  FcmService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseService.firestore,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Sets the navigation callback executed when a notification is tapped.
  void setTapCallback(Function(Map<String, dynamic> data) callback) {
    _onNotificationTapCallback = callback;
  }

  /// Initializes FCM, creates Android high-importance notification channel,
  /// configures foreground presentation, and sets up message event listeners.
  Future<void> initialize() async {
    try {
      // 1. Android Notification Channel Setup
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      // 2. Initialize Local Notifications Plugin (Foreground Banner)
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && _onNotificationTapCallback != null) {
            try {
              final Uri uri = Uri.parse(response.payload!);
              final params = uri.queryParameters;
              _onNotificationTapCallback!(params);
            } catch (e) {
              debugPrint('Error parsing notification payload URI: $e');
            }
          }
        },
      );

      // 3. Foreground Notification Presentation Options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground Message Listener
      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message, channel);
      });

      // 5. Background Tap Listener (App opened from background state)
      _openedAppSub?.cancel();
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 6. Terminated App Launch Check (App launched from cold start via notification tap)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('FCMService initialized cleanly.');
    } catch (e, stack) {
      debugPrint('FCMService Initialization Warning: $e\n$stack');
    }
  }

  /// Handles incoming foreground messages by displaying a high-importance Android notification banner.
  void _handleForegroundMessage(
      RemoteMessage message, AndroidNotificationChannel channel) {
    debugPrint('FCM Foreground Message Received: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Cipher-X Alert';
    final body = notification?.body ?? data['body'] ?? 'Operational notification received.';

    // Construct query parameters string for tap payload
    final Uri payloadUri = Uri(queryParameters: Map<String, String>.from(
      data.map((key, value) => MapEntry(key, value.toString())),
    ));

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: payloadUri.toString(),
    );
  }

  /// Extracts message payload and triggers notification tap navigation.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM Notification Tapped: ${message.data}');
    if (_onNotificationTapCallback != null) {
      _onNotificationTapCallback!(message.data);
    }
  }

  /// Requests Android / OS notification permissions.
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM Permission Status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Registers or updates the device FCM token in Firestore under `users/{userId}/devices/{deviceId}`.
  Future<void> registerDeviceToken({
    required String userId,
    required String organizationId,
    required String role,
  }) async {
    if (userId.isEmpty || organizationId.isEmpty) return;

    try {
      await requestPermission();

      final String? token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM Token unavailable for user: $userId');
        return;
      }

      final String platformName = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'desktop';

      final String deviceId = _getStableDeviceId(userId, platformName);
      _currentUserId = userId;
      _currentDeviceId = deviceId;

      final deviceToken = DeviceToken(
        deviceId: deviceId,
        userId: userId,
        organizationId: organizationId,
        fcmToken: token,
        platform: platformName,
        role: role,
        enabled: true,
      );

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId);

      await docRef.set(deviceToken.toFirestore(), SetOptions(merge: true));
      debugPrint('FCM Token registered cleanly for user: $userId (device: $deviceId)');

      // Listen for token rotation
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        if (_currentUserId == userId && _currentDeviceId == deviceId) {
          await docRef.update({
            'fcmToken': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('FCM Token refreshed for user: $userId');
        }
      });
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Disables device FCM token in Firestore upon user logout.
  /// Prevents User B from receiving notifications intended for User A on the same physical device.
  Future<void> unregisterDeviceToken() async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('devices')
          .doc(_currentDeviceId!);

      await docRef.update({
        'enabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _tokenRefreshSub?.cancel();
      _currentUserId = null;
      _currentDeviceId = null;
      debugPrint('FCM Token disabled on logout.');
    } catch (e) {
      debugPrint('Error unregistering FCM token on logout: $e');
    }
  }

  /// Generates a deterministic client device ID.
  String _getStableDeviceId(String userId, String platform) {
    final cleanUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return 'dev_${platform}_$cleanUserId';
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
  }
}

/// Riverpod provider exposing singleton FcmService instance.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService();
  ref.onDispose(() => service.dispose());
  return service;
});
