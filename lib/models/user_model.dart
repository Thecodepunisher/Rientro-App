import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello utente RIENTRO
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fcmToken;
  final UserSettings settings;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    required this.isAnonymous,
    required this.createdAt,
    this.lastLoginAt,
    this.fcmToken,
    this.settings = const UserSettings(),
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
      settings: UserSettings.fromMap(data['settings'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'fcmToken': fcmToken,
      'settings': settings.toMap(),
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    bool? isAnonymous,
    DateTime? lastLoginAt,
    String? fcmToken,
    UserSettings? settings,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      fcmToken: fcmToken ?? this.fcmToken,
      settings: settings ?? this.settings,
    );
  }
  
  /// Nome da mostrare (displayName o email o "Utente")
  String get name => displayName ?? email?.split('@').first ?? 'Utente';
}

/// Impostazioni utente
class UserSettings {
  final bool silentModeDefault;
  final int defaultDurationMinutes;
  final bool autoLocationEnabled;
  final bool shakeForSOSEnabled;
  final List<String> defaultContactIds;

  const UserSettings({
    this.silentModeDefault = false,
    this.defaultDurationMinutes = 30,
    this.autoLocationEnabled = true,
    this.shakeForSOSEnabled = true,
    this.defaultContactIds = const [],
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      silentModeDefault: map['silentModeDefault'] as bool? ?? false,
      defaultDurationMinutes: map['defaultDurationMinutes'] as int? ?? 30,
      autoLocationEnabled: map['autoLocationEnabled'] as bool? ?? true,
      shakeForSOSEnabled: map['shakeForSOSEnabled'] as bool? ?? true,
      defaultContactIds: List<String>.from(map['defaultContactIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'silentModeDefault': silentModeDefault,
      'defaultDurationMinutes': defaultDurationMinutes,
      'autoLocationEnabled': autoLocationEnabled,
      'shakeForSOSEnabled': shakeForSOSEnabled,
      'defaultContactIds': defaultContactIds,
    };
  }

  UserSettings copyWith({
    bool? silentModeDefault,
    int? defaultDurationMinutes,
    bool? autoLocationEnabled,
    bool? shakeForSOSEnabled,
    List<String>? defaultContactIds,
  }) {
    return UserSettings(
      silentModeDefault: silentModeDefault ?? this.silentModeDefault,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
      autoLocationEnabled: autoLocationEnabled ?? this.autoLocationEnabled,
      shakeForSOSEnabled: shakeForSOSEnabled ?? this.shakeForSOSEnabled,
      defaultContactIds: defaultContactIds ?? this.defaultContactIds,
    );
  }
}

