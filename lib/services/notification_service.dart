import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled here
  if (kDebugMode) print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State management with ValueNotifiers
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<NotificationModel>> notifications =
      ValueNotifier<List<NotificationModel>>([]);

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  StreamSubscription<User?>? _authSubscription;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) print('User granted provisional permission');
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
      return; // No need to continue setup if permission denied
    }

    // 2. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Create High Importance Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Yüksek Öncelikli Bildirimler', // title
      description: 'Zorunlu ve önemli bildirimler için kullanılır.',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap logic here
        if (kDebugMode) print('Notification payload: ${details.payload}');
      },
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
        // Show local notification
        _showNotification(message);
        // Save to Firestore
        _saveNotificationToFirestore(message);
      }
    });

    // 4. Handle Background Message Setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) print('FCM Token: $token');
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // 6. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // 7. Listen to auth changes to start/stop notification stream
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListeningToNotifications(user.uid);
      } else {
        _stopListeningToNotifications();
      }
    });

    // Initial check if already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startListeningToNotifications(currentUser.uid);
    }
  }

  void _startListeningToNotifications(String uid) {
    _notificationSubscription?.cancel();
    debugPrint('[Notifications] Starting to listen for notifications for user: $uid');
    _notificationSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[Notifications] Received ${snapshot.docs.length} notifications from Firestore',
            );
            final List<NotificationModel> notifs = snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
            notifications.value = notifs;
            unreadCount.value = notifs.where((n) => !n.isRead).length;
            debugPrint('[Notifications] Unread count: ${unreadCount.value}');
          },
          onError: (error) {
            debugPrint('[Notifications] Error listening to notifications: $error');
          },
        );
  }

  void _stopListeningToNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    notifications.value = [];
    unreadCount.value = 0;
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': message.notification?.title ?? '',
            'body': message.notification?.body ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': message.data['type'],
            'data': message.data,
          });
    } catch (e) {
      if (kDebugMode) print('Error saving notification to Firestore: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting notification: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      if (kDebugMode) print('Saving FCM Token: $token');
      await AuthService().updateFcmToken(token);
    } catch (e) {
      if (kDebugMode) print('Error saving token: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // id
          'Yüksek Öncelikli Bildirimler', // title
          channelDescription: 'Zorunlu ve önemli bildirimler için kullanılır.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data['route'], // Example valid payload
    );
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
