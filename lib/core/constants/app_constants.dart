/// Costanti dell'applicazione RIENTRO
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'RIENTRO';
  static const String appVersion = '1.0.0';
  
  // Timing (in minuti)
  static const int defaultCheckIntervalMinutes = 15;
  static const int gracePeriodMinutes = 5;
  static const int escalationDelayMinutes = 10;
  static const int maxRientroDurationHours = 24;
  
  // Escalation Levels
  static const int escalationLevel1 = 1; // Soft notification
  static const int escalationLevel2 = 2; // Urgent notification
  static const int escalationLevel3 = 3; // Emergency - contact notified
  static const int escalationLevelSOS = 4; // Manual SOS
  
  // Location
  static const double locationAccuracyThreshold = 100; // metri
  static const int locationTimeoutSeconds = 30;
  
  // Battery
  static const int lowBatteryThreshold = 15;
  static const int criticalBatteryThreshold = 5;
  
  // SOS
  static const int sosMultiTapCount = 5;
  static const int sosMultiTapWindowMs = 2000;
  static const double sosShakeThreshold = 20.0;
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String rientriCollection = 'rientri';
  static const String contactsCollection = 'contacts';
  static const String notificationsCollection = 'notifications';
  
  // Shared Preferences Keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefLastRientroId = 'last_rientro_id';
  static const String prefDefaultContacts = 'default_contacts';
  static const String prefSilentModeEnabled = 'silent_mode_enabled';
}

/// Stati possibili di un rientro
enum RientroStatus {
  active('active', 'In corso'),
  late('late', 'In ritardo'),
  emergency('emergency', 'Emergenza'),
  completed('completed', 'Completato'),
  cancelled('cancelled', 'Annullato');
  
  final String value;
  final String label;
  
  const RientroStatus(this.value, this.label);
  
  static RientroStatus fromString(String value) {
    return RientroStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RientroStatus.active,
    );
  }
  
  bool get isActive => this == RientroStatus.active || this == RientroStatus.late;
  bool get isEmergency => this == RientroStatus.emergency;
  bool get isClosed => this == RientroStatus.completed || this == RientroStatus.cancelled;
}

/// Tipi di notifica
enum NotificationType {
  rientroStarted('rientro_started', 'Rientro avviato'),
  checkIn('check_in', 'Tutto ok?'),
  late('late', 'Ritardo'),
  emergency('emergency', 'Emergenza'),
  completed('completed', 'Rientro completato'),
  sos('sos', 'SOS');
  
  final String value;
  final String label;
  
  const NotificationType(this.value, this.label);
}

