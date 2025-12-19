import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello per un contatto di emergenza
class EmergencyContactModel {
  final String id;
  final String userId; // proprietario del contatto
  final String name;
  final String phoneNumber;
  final String? email;
  final String? fcmToken; // se il contatto ha l'app
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? lastNotifiedAt;

  const EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.fcmToken,
    this.isPrimary = false,
    required this.createdAt,
    this.lastNotifiedAt,
  });

  factory EmergencyContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmergencyContactModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String?,
      fcmToken: data['fcmToken'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastNotifiedAt: (data['lastNotifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'fcmToken': fcmToken,
      'isPrimary': isPrimary,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastNotifiedAt': lastNotifiedAt != null 
        ? Timestamp.fromDate(lastNotifiedAt!) 
        : null,
    };
  }

  EmergencyContactModel copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? fcmToken,
    bool? isPrimary,
    DateTime? lastNotifiedAt,
  }) {
    return EmergencyContactModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
    );
  }

  /// Numero formattato per display
  String get formattedPhone {
    // Semplice formattazione italiana
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('+39')) {
      clean = clean.substring(3);
    }
    if (clean.length == 10) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    return phoneNumber;
  }

  /// Iniziali del nome
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Ha l'app installata?
  bool get hasApp => fcmToken != null && fcmToken!.isNotEmpty;
}

/// Crea un nuovo contatto di emergenza
EmergencyContactModel createEmergencyContact({
  required String id,
  required String userId,
  required String name,
  required String phoneNumber,
  String? email,
  bool isPrimary = false,
}) {
  return EmergencyContactModel(
    id: id,
    userId: userId,
    name: name,
    phoneNumber: phoneNumber,
    email: email,
    isPrimary: isPrimary,
    createdAt: DateTime.now(),
  );
}

