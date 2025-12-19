import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Handler per messaggi in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Gestione notifiche in background
  debugPrint('Background message: ${message.messageId}');
}

/// Servizio per notifiche push
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  
  /// Token FCM corrente
  static String? get fcmToken => _fcmToken;

  /// Inizializza il servizio notifiche
  static Future<void> initialize() async {
    // Richiedi permessi
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // Importante per emergenze
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // Imposta handler background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ottieni token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Ascolta refresh token
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('FCM Token refreshed: $token');
    });

    // Configura foreground presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Ascolta messaggi in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Ascolta tap su notifica
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Controlla se app aperta da notifica
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Gestisce messaggi ricevuti in foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    // Qui puoi mostrare una notifica in-app o aggiornare lo stato
    final data = message.data;
    final type = data['type'] as String?;
    
    switch (type) {
      case 'check_in':
        // Richiesta check-in
        _onCheckInRequest?.call();
        break;
      case 'emergency':
        // Notifica emergenza (per contatti)
        _onEmergencyNotification?.call(data);
        break;
      case 'rientro_completed':
        // Rientro completato (per contatti)
        _onRientroCompleted?.call(data);
        break;
    }
  }

  /// Gestisce tap su notifica
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    final data = message.data;
    final type = data['type'] as String?;
    final rientroId = data['rientroId'] as String?;
    
    // Naviga alla schermata appropriata
    _onNotificationTap?.call(type, rientroId, data);
  }

  // Callbacks per eventi notifica
  static VoidCallback? _onCheckInRequest;
  static Function(Map<String, dynamic>)? _onEmergencyNotification;
  static Function(Map<String, dynamic>)? _onRientroCompleted;
  static Function(String?, String?, Map<String, dynamic>)? _onNotificationTap;

  /// Registra callback per richieste check-in
  static void onCheckInRequest(VoidCallback callback) {
    _onCheckInRequest = callback;
  }

  /// Registra callback per notifiche emergenza
  static void onEmergencyNotification(
    Function(Map<String, dynamic>) callback,
  ) {
    _onEmergencyNotification = callback;
  }

  /// Registra callback per rientro completato
  static void onRientroCompleted(
    Function(Map<String, dynamic>) callback,
  ) {
    _onRientroCompleted = callback;
  }

  /// Registra callback per tap su notifica
  static void onNotificationTap(
    Function(String?, String?, Map<String, dynamic>) callback,
  ) {
    _onNotificationTap = callback;
  }

  /// Sottoscrivi a topic (es. per contatti di emergenza)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Disiscriviti da topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Sottoscrivi al topic di un utente specifico (per ricevere notifiche dei suoi rientri)
  static Future<void> subscribeToUserRientri(String userId) async {
    await subscribeToTopic('user_$userId');
  }

  /// Disiscriviti dal topic di un utente
  static Future<void> unsubscribeFromUserRientri(String userId) async {
    await unsubscribeFromTopic('user_$userId');
  }

  /// Verifica se le notifiche sono abilitate
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Apri impostazioni notifiche del sistema
  static Future<void> openNotificationSettings() async {
    await _messaging.requestPermission();
  }
}

/// Tipi di notifica per il payload
class NotificationPayload {
  final String type;
  final String? rientroId;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? extra;

  NotificationPayload({
    required this.type,
    this.rientroId,
    this.userId,
    this.userName,
    this.extra,
  });

  Map<String, String> toData() {
    return {
      'type': type,
      if (rientroId != null) 'rientroId': rientroId!,
      if (userId != null) 'userId': userId!,
      if (userName != null) 'userName': userName!,
      if (extra != null) 'extra': jsonEncode(extra),
    };
  }

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      type: data['type'] as String? ?? '',
      rientroId: data['rientroId'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      extra: data['extra'] != null 
        ? jsonDecode(data['extra'] as String) as Map<String, dynamic>
        : null,
    );
  }
}

