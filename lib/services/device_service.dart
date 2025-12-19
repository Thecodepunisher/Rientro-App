import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'package:rientro/core/constants/app_constants.dart';

/// Servizio per monitoraggio dispositivo
class DeviceService {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;

  /// Ottieni livello batteria
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return -1;
    }
  }

  /// Stream livello batteria
  Stream<BatteryState> get batteryStateStream => _battery.onBatteryStateChanged;

  /// Verifica se batteria è bassa
  Future<bool> isBatteryLow() async {
    final level = await getBatteryLevel();
    return level > 0 && level <= AppConstants.lowBatteryThreshold;
  }

  /// Verifica se batteria è critica
  Future<bool> isBatteryCritical() async {
    final level = await getBatteryLevel();
    return level > 0 && level <= AppConstants.criticalBatteryThreshold;
  }

  /// Verifica connessione internet
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Stream stato connessione
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Verifica tipo di connessione
  Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    
    if (result == ConnectivityResult.wifi) {
      return 'WiFi';
    } else if (result == ConnectivityResult.mobile) {
      return 'Mobile';
    } else if (result == ConnectivityResult.ethernet) {
      return 'Ethernet';
    } else {
      return 'Disconnesso';
    }
  }

  /// Attiva rilevamento shake per SOS
  void startShakeDetection({
    required Function() onShakeSOS,
  }) {
    _shakeSubscription?.cancel();
    _shakeCount = 0;
    _lastShakeTime = null;
    
    _shakeSubscription = accelerometerEventStream().listen((event) {
      // Calcola accelerazione totale
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      
      // Rileva shake
      if (acceleration > AppConstants.sosShakeThreshold) {
        final now = DateTime.now();
        
        // Reset contatore se troppo tempo è passato
        if (_lastShakeTime != null) {
          final diff = now.difference(_lastShakeTime!).inMilliseconds;
          if (diff > AppConstants.sosMultiTapWindowMs) {
            _shakeCount = 0;
          }
        }
        
        _shakeCount++;
        _lastShakeTime = now;
        
        // Se abbiamo abbastanza shake, attiva SOS
        if (_shakeCount >= AppConstants.sosMultiTapCount) {
          onShakeSOS();
          _shakeCount = 0;
        }
      }
    });
  }

  /// Ferma rilevamento shake
  void stopShakeDetection() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
    _shakeCount = 0;
    _lastShakeTime = null;
  }

  /// Ottieni stato completo dispositivo
  Future<DeviceStatus> getDeviceStatus() async {
    final batteryLevel = await getBatteryLevel();
    final connected = await isConnected();
    final connectionType = await getConnectionType();
    
    return DeviceStatus(
      batteryLevel: batteryLevel,
      isBatteryLow: batteryLevel > 0 && batteryLevel <= AppConstants.lowBatteryThreshold,
      isBatteryCritical: batteryLevel > 0 && batteryLevel <= AppConstants.criticalBatteryThreshold,
      isConnected: connected,
      connectionType: connectionType,
    );
  }

  /// Dispose
  void dispose() {
    stopShakeDetection();
  }
}

/// Stato dispositivo
class DeviceStatus {
  final int batteryLevel;
  final bool isBatteryLow;
  final bool isBatteryCritical;
  final bool isConnected;
  final String connectionType;

  const DeviceStatus({
    required this.batteryLevel,
    required this.isBatteryLow,
    required this.isBatteryCritical,
    required this.isConnected,
    required this.connectionType,
  });

  bool get hasCriticalIssue => isBatteryCritical || !isConnected;
  bool get hasWarning => isBatteryLow;
}

