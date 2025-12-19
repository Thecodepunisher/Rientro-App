import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Utility per feedback aptico
/// Fornisce feedback tattile appropriato per ogni azione
class Haptics {
  Haptics._();
  
  /// Feedback leggero - per tap normali
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Feedback medio - per azioni importanti
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Feedback pesante - per azioni critiche
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Feedback di selezione - per toggle, picker
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
  
  /// Feedback di successo - pattern crescente
  static Future<void> success() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(pattern: [0, 50, 100, 50], intensities: [128, 255]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
  
  /// Feedback di warning - pattern di attenzione
  static Future<void> warning() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(pattern: [0, 100, 100, 100], intensities: [200, 200]);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
  
  /// Feedback di errore - pattern deciso
  static Future<void> error() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(pattern: [0, 150, 100, 150, 100, 150], intensities: [255, 255, 255]);
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    }
  }
  
  /// Feedback SOS - pattern urgente riconoscibile
  static Future<void> sos() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      // Pattern SOS: ... --- ... (breve breve breve, lungo lungo lungo, breve breve breve)
      await Vibration.vibrate(
        pattern: [
          0, 100, 100, 100, 100, 100, // ...
          200, 300, 100, 300, 100, 300, // ---
          200, 100, 100, 100, 100, 100, // ...
        ],
        intensities: [255, 255, 255, 255, 255, 255, 255, 255, 255],
      );
    } else {
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }
  
  /// Feedback per check-in - notifica soft
  static Future<void> checkIn() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 200, amplitude: 128);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
}

