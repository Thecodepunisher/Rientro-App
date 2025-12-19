import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/services/rientro_service.dart';
import 'package:rientro/services/location_service.dart';
import 'package:rientro/services/device_service.dart';
import 'package:rientro/models/rientro_model.dart';
import 'package:rientro/features/auth/providers/auth_provider.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Provider del servizio rientri
final rientroServiceProvider = Provider<RientroService>((ref) {
  return RientroService();
});

/// Provider del servizio location
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider del servizio device
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Provider del rientro attivo
final activeRientroProvider = StreamProvider<RientroModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  final rientroService = ref.watch(rientroServiceProvider);
  return rientroService.getActiveRientroStream(user.uid);
});

/// Provider per verificare se c'è un rientro attivo
final hasActiveRientroProvider = Provider<bool>((ref) {
  final rientro = ref.watch(activeRientroProvider).value;
  return rientro != null && rientro.status.isActive;
});

/// Provider storico rientri
final rientroHistoryProvider = FutureProvider<List<RientroModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final rientroService = ref.watch(rientroServiceProvider);
  return rientroService.getRientroHistory(user.uid);
});

/// Provider per le azioni sui rientri
final rientroActionsProvider = Provider<RientroActions>((ref) {
  final rientroService = ref.watch(rientroServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  return RientroActions(
    rientroService: rientroService,
    locationService: locationService,
    deviceService: deviceService,
    userId: user?.uid,
  );
});

/// Classe per le azioni sui rientri
class RientroActions {
  final RientroService rientroService;
  final LocationService locationService;
  final DeviceService deviceService;
  final String? userId;

  RientroActions({
    required this.rientroService,
    required this.locationService,
    required this.deviceService,
    this.userId,
  });

  /// Crea un nuovo rientro
  Future<RientroModel?> startRientro({
    required int durationMinutes,
    required List<String> contactIds,
    String? destinationName,
    GeoPoint? destinationLocation,
    bool silentMode = false,
  }) async {
    if (userId == null) return null;
    if (contactIds.isEmpty) return null;

    // Ottieni posizione corrente
    final startLocation = await locationService.getCurrentGeoPoint();
    
    // Ottieni stato dispositivo
    final deviceStatus = await deviceService.getDeviceStatus();

    final rientro = await rientroService.createRientro(
      userId: userId!,
      durationMinutes: durationMinutes,
      contactIds: contactIds,
      startLocation: startLocation,
      destinationLocation: destinationLocation,
      destinationName: destinationName,
      silentMode: silentMode,
    );

    // Aggiorna stato dispositivo
    if (deviceStatus.batteryLevel > 0) {
      await rientroService.updateDeviceStatus(
        rientro.id,
        batteryLevel: deviceStatus.batteryLevel,
        isConnected: deviceStatus.isConnected,
      );
    }

    return rientro;
  }

  /// Conferma check-in (sto bene)
  Future<void> confirmCheckIn(String rientroId) async {
    final location = await locationService.getCurrentGeoPoint();
    await rientroService.updatePing(rientroId, location: location);
    
    // Aggiorna stato dispositivo
    final deviceStatus = await deviceService.getDeviceStatus();
    await rientroService.updateDeviceStatus(
      rientroId,
      batteryLevel: deviceStatus.batteryLevel,
      isConnected: deviceStatus.isConnected,
    );
  }

  /// Aggiorna posizione
  Future<void> updateLocation(String rientroId) async {
    final location = await locationService.getCurrentGeoPoint();
    if (location != null) {
      await rientroService.updateLocation(rientroId, location);
    }
  }

  /// Attiva SOS
  Future<void> activateSOS(String rientroId) async {
    final location = await locationService.getCurrentGeoPoint();
    await rientroService.activateSOS(rientroId, location: location);
  }

  /// Completa rientro (sono arrivato)
  Future<void> completeRientro(String rientroId) async {
    await rientroService.completeRientro(rientroId);
  }

  /// Annulla rientro
  Future<void> cancelRientro(String rientroId) async {
    await rientroService.cancelRientro(rientroId);
  }

  /// Crea SOS immediato (senza rientro attivo)
  Future<RientroModel?> createSOSRientro(List<String> contactIds) async {
    if (userId == null) return null;
    if (contactIds.isEmpty) return null;

    final location = await locationService.getCurrentGeoPoint();

    // Crea rientro in stato emergenza
    final rientro = await rientroService.createRientro(
      userId: userId!,
      durationMinutes: 60, // durata fittizia
      contactIds: contactIds,
      startLocation: location,
    );

    // Attiva immediatamente SOS
    await rientroService.activateSOS(rientro.id, location: location);

    return rientro;
  }
}

/// Provider per i dati del form nuovo rientro
final newRientroFormProvider = StateNotifierProvider<NewRientroFormNotifier, NewRientroForm>((ref) {
  return NewRientroFormNotifier();
});

class NewRientroForm {
  final int durationMinutes;
  final List<String> selectedContactIds;
  final String? destinationName;
  final GeoPoint? destinationLocation;
  final bool silentMode;

  const NewRientroForm({
    this.durationMinutes = 30,
    this.selectedContactIds = const [],
    this.destinationName,
    this.destinationLocation,
    this.silentMode = false,
  });

  NewRientroForm copyWith({
    int? durationMinutes,
    List<String>? selectedContactIds,
    String? destinationName,
    GeoPoint? destinationLocation,
    bool? silentMode,
  }) {
    return NewRientroForm(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      destinationName: destinationName ?? this.destinationName,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      silentMode: silentMode ?? this.silentMode,
    );
  }

  bool get isValid => selectedContactIds.isNotEmpty && durationMinutes > 0;
}

class NewRientroFormNotifier extends StateNotifier<NewRientroForm> {
  NewRientroFormNotifier() : super(const NewRientroForm());

  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  void setContacts(List<String> contactIds) {
    state = state.copyWith(selectedContactIds: contactIds);
  }

  void addContact(String contactId) {
    if (!state.selectedContactIds.contains(contactId)) {
      state = state.copyWith(
        selectedContactIds: [...state.selectedContactIds, contactId],
      );
    }
  }

  void removeContact(String contactId) {
    state = state.copyWith(
      selectedContactIds: state.selectedContactIds
          .where((id) => id != contactId)
          .toList(),
    );
  }

  void setDestination(String? name, GeoPoint? location) {
    state = state.copyWith(
      destinationName: name,
      destinationLocation: location,
    );
  }

  void setSilentMode(bool value) {
    state = state.copyWith(silentMode: value);
  }

  void reset() {
    state = const NewRientroForm();
  }
}

/// Provider stato dispositivo attuale
final deviceStatusProvider = FutureProvider<DeviceStatus>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.getDeviceStatus();
});

