import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rientro/services/auth_service.dart';
import 'package:rientro/services/notification_service.dart';
import 'package:rientro/models/user_model.dart';

/// Provider del servizio auth
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider dello stato di autenticazione
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider dell'utente corrente
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Provider del profilo utente da Firestore
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return authService.getUserProfileStream();
});

/// Provider per le azioni di auth
final authActionsProvider = Provider<AuthActions>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthActions(authService);
});

/// Classe per le azioni di autenticazione
class AuthActions {
  final AuthService _authService;
  
  AuthActions(this._authService);

  /// Login anonimo
  Future<void> signInAnonymously() async {
    await _authService.signInAnonymously();
    await _updateFcmToken();
  }

  /// Login con email
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    await _updateFcmToken();
  }

  /// Registrazione
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _updateFcmToken();
  }

  /// Collega account anonimo
  Future<void> linkAnonymousToEmail({
    required String email,
    required String password,
  }) async {
    await _authService.linkAnonymousToEmail(
      email: email,
      password: password,
    );
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Logout
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Elimina account
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
  }

  /// Aggiorna impostazioni
  Future<void> updateSettings(UserSettings settings) async {
    await _authService.updateUserSettings(settings);
  }

  /// Aggiorna FCM token
  Future<void> _updateFcmToken() async {
    final token = NotificationService.fcmToken;
    if (token != null) {
      await _authService.updateFcmToken(token);
    }
  }
}

/// Provider dello stato loading auth
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider per errori auth
final authErrorProvider = StateProvider<String?>((ref) => null);

