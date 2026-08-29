import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler untuk FCM saat aplikasi di-terminate / di background.
/// Harus diletakkan di top-level function dengan anotasi entry-point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('📬 [FCM Background Message]: ${message.messageId} - ${message.notification?.title}');
}

/// Service terpusat untuk mengelola Firebase Cloud Messaging (FCM)
/// dan notifikasi lokal (FlutterLocalNotificationsPlugin).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;

  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Channel notifikasi untuk Android (High Importance)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'muratech_hris_channel',
    'Notifikasi HRIS Muratech',
    description: 'Channel pemberitahuan aktivitas absensi, cuti, lembur, dan pengumuman.',
    importance: Importance.high,
    playSound: true,
  );

  bool _isInitialized = false;

  /// Inisialisasi seluruh listener dan konfigurasi notifikasi
  Future<void> initialize({
    void Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    if (_isInitialized) return;

    try {
      final fcm = _fcm;
      if (fcm == null) {
        debugPrint('ℹ️ [NotificationService]: Firebase belum diinisialisasi, notifikasi diskip.');
        return;
      }

      // 1. Request izin notifikasi (Wajib untuk iOS dan Android 13+)
      final settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [FCM Permission Status]: ${settings.authorizationStatus}');

      // 2. Setup Flutter Local Notifications untuk Android & iOS foreground
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && onNotificationOpened != null) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              onNotificationOpened(RemoteMessage(data: data));
            } catch (_) {}
          }
        },
      );

      // Buat Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. Konfigurasi notifikasi saat aplikasi berada di Foreground
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listener: Pesan diterima saat aplikasi aktif (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [FCM Foreground Message]: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // Listener: Pengguna menekan notifikasi saat aplikasi di background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👆 [FCM Notification Clicked]: ${message.data}');
        onNotificationOpened?.call(message);
      });

      // Cek apakah aplikasi dibuka pertama kali dari notifikasi (Terminated State)
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [FCM Initial Message]: ${initialMessage.data}');
        onNotificationOpened?.call(initialMessage);
      }

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
    } catch (e) {
      debugPrint('ℹ️ [NotificationService Init Note]: $e');
    }
  }

  /// Menampilkan popup notifikasi lokal saat foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF0D9488),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Mengambil FCM Device Token untuk didaftarkan ke backend HRIS
  Future<String?> getFcmToken() async {
    try {
      final fcm = _fcm;
      if (fcm == null) return null;
      final token = await fcm.getToken();
      debugPrint('🔑 [FCM Device Token]: $token');
      return token;
    } catch (e) {
      debugPrint('ℹ️ [FCM Get Token Note]: $e');
      return null;
    }
  }

  /// Stream listener ketika token FCM diperbarui
  Stream<String> get onTokenRefresh {
    final fcm = _fcm;
    if (fcm == null) return const Stream.empty();
    return fcm.onTokenRefresh;
  }

  /// Berlangganan ke topik tertentu (misal: 'announcements', 'all-employees')
  Future<void> subscribeToTopic(String topic) async {
    try {
      final fcm = _fcm;
      if (fcm != null) {
        await fcm.subscribeToTopic(topic);
        debugPrint('📢 Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('ℹ️ Error subscribing to topic $topic: $e');
    }
  }

  /// Berhenti berlangganan dari topik
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final fcm = _fcm;
      if (fcm != null) {
        await fcm.unsubscribeFromTopic(topic);
        debugPrint('🔕 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('ℹ️ Error unsubscribing from topic $topic: $e');
    }
  }
}
