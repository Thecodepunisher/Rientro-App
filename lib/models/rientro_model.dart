import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Modello principale per un rientro
class RientroModel {
  final String id;
  final String userId;
  final RientroStatus status;
  final DateTime startTime;
  final DateTime expectedEndTime;
  final DateTime? actualEndTime;
  final GeoPoint? startLocation;
  final GeoPoint? destinationLocation;
  final String? destinationName;
  final GeoPoint? lastKnownLocation;
  final DateTime? lastPing;
  final DateTime? lastCheckIn;
  final bool silentMode;
  final int escalationLevel;
  final List<String> contactIds;
  final int? batteryLevel;
  final bool? isConnected;
  final String? notes;

  const RientroModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startTime,
    required this.expectedEndTime,
    this.actualEndTime,
    this.startLocation,
    this.destinationLocation,
    this.destinationName,
    this.lastKnownLocation,
    this.lastPing,
    this.lastCheckIn,
    this.silentMode = false,
    this.escalationLevel = 0,
    this.contactIds = const [],
    this.batteryLevel,
    this.isConnected,
    this.notes,
  });

  factory RientroModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RientroModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      status: RientroStatus.fromString(data['status'] as String? ?? 'active'),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedEndTime: (data['expectedEndTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualEndTime: (data['actualEndTime'] as Timestamp?)?.toDate(),
      startLocation: data['startLocation'] as GeoPoint?,
      destinationLocation: data['destinationLocation'] as GeoPoint?,
      destinationName: data['destinationName'] as String?,
      lastKnownLocation: data['lastKnownLocation'] as GeoPoint?,
      lastPing: (data['lastPing'] as Timestamp?)?.toDate(),
      lastCheckIn: (data['lastCheckIn'] as Timestamp?)?.toDate(),
      silentMode: data['silentMode'] as bool? ?? false,
      escalationLevel: data['escalationLevel'] as int? ?? 0,
      contactIds: List<String>.from(data['contactIds'] ?? []),
      batteryLevel: data['batteryLevel'] as int?,
      isConnected: data['isConnected'] as bool?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status.value,
      'startTime': Timestamp.fromDate(startTime),
      'expectedEndTime': Timestamp.fromDate(expectedEndTime),
      'actualEndTime': actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'startLocation': startLocation,
      'destinationLocation': destinationLocation,
      'destinationName': destinationName,
      'lastKnownLocation': lastKnownLocation,
      'lastPing': lastPing != null ? Timestamp.fromDate(lastPing!) : null,
      'lastCheckIn': lastCheckIn != null ? Timestamp.fromDate(lastCheckIn!) : null,
      'silentMode': silentMode,
      'escalationLevel': escalationLevel,
      'contactIds': contactIds,
      'batteryLevel': batteryLevel,
      'isConnected': isConnected,
      'notes': notes,
    };
  }

  RientroModel copyWith({
    RientroStatus? status,
    DateTime? actualEndTime,
    GeoPoint? lastKnownLocation,
    DateTime? lastPing,
    DateTime? lastCheckIn,
    bool? silentMode,
    int? escalationLevel,
    int? batteryLevel,
    bool? isConnected,
  }) {
    return RientroModel(
      id: id,
      userId: userId,
      status: status ?? this.status,
      startTime: startTime,
      expectedEndTime: expectedEndTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      startLocation: startLocation,
      destinationLocation: destinationLocation,
      destinationName: destinationName,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      lastPing: lastPing ?? this.lastPing,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      silentMode: silentMode ?? this.silentMode,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      contactIds: contactIds,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isConnected: isConnected ?? this.isConnected,
      notes: notes,
    );
  }

  /// Calcola se il rientro è in ritardo
  bool get isLate => DateTime.now().isAfter(expectedEndTime);
  
  /// Calcola minuti di ritardo
  int get minutesLate {
    if (!isLate) return 0;
    return DateTime.now().difference(expectedEndTime).inMinutes;
  }
  
  /// Tempo rimanente in minuti (negativo se in ritardo)
  int get minutesRemaining {
    return expectedEndTime.difference(DateTime.now()).inMinutes;
  }
  
  /// Percentuale di completamento (0.0 - 1.0+)
  double get progress {
    final totalDuration = expectedEndTime.difference(startTime).inMinutes;
    final elapsed = DateTime.now().difference(startTime).inMinutes;
    if (totalDuration <= 0) return 1.0;
    return elapsed / totalDuration;
  }
  
  /// Minuti dall'ultimo ping
  int? get minutesSinceLastPing {
    if (lastPing == null) return null;
    return DateTime.now().difference(lastPing!).inMinutes;
  }
  
  /// Durata totale in minuti
  int get durationMinutes {
    return expectedEndTime.difference(startTime).inMinutes;
  }
}

/// Crea un nuovo rientro con valori default
RientroModel createNewRientro({
  required String id,
  required String userId,
  required int durationMinutes,
  required List<String> contactIds,
  GeoPoint? startLocation,
  GeoPoint? destinationLocation,
  String? destinationName,
  bool silentMode = false,
}) {
  final now = DateTime.now();
  return RientroModel(
    id: id,
    userId: userId,
    status: RientroStatus.active,
    startTime: now,
    expectedEndTime: now.add(Duration(minutes: durationMinutes)),
    startLocation: startLocation,
    destinationLocation: destinationLocation,
    destinationName: destinationName,
    lastPing: now,
    lastKnownLocation: startLocation,
    silentMode: silentMode,
    escalationLevel: 0,
    contactIds: contactIds,
  );
}

