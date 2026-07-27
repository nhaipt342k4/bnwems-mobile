import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();

  String? _deviceToken;
  String? get deviceToken => _deviceToken;

  final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageStream => _messageStreamController.stream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 1. Cấu hình Local Notifications (Android Channel cho Popup Nổi / System Status Bar Banner)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Thông báo quan trọng',
        description: 'Kênh thông báo nổi hiện trường',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 2. Xin quyền thông báo (iOS & Android 13+) & Cấu hình Bật Popup Nổi Hệ Thống
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Lấy Device Token & In nổi bật ra Console Log ngay khi mở app
      await _fetchDeviceToken();

      // 4. Lắng nghe tin nhắn khi App ở Foreground / Background (Bật Banner Nổi Hệ Thống)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _messageStreamController.add(message);

        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                visibility: NotificationVisibility.public,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        }
      });

      // 5. Tự động đăng ký Token với Backend nếu user đã đăng nhập
      final token = await _storageService.getToken();
      if (token != null && _deviceToken != null) {
        await registerTokenWithBackend(_deviceToken!);
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  Future<String?> _fetchDeviceToken() async {
    try {
      _deviceToken = await _messaging.getToken();
      if (_deviceToken != null) {
        print('\n================================================================');
        print('🔥 [FCM DEVICE TOKEN DE COPY VAO API TEST CUA BACH]:');
        print(_deviceToken);
        print('================================================================\n');

        developer.log(
          _deviceToken!,
          name: 'FCM_DEVICE_TOKEN',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM Device Token: $e');
      }
    }
    return _deviceToken;
  }

  Future<bool> registerTokenWithBackend(String tokenStr) async {
    try {
      await _apiClient.fetchData<dynamic>(
        '/notifications/device-token',
        method: 'POST',
        body: {'deviceToken': tokenStr},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
