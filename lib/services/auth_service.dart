import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rientro/models/user_model.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Servizio di autenticazione Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream dell'utente corrente
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utente corrente
  User? get currentUser => _auth.currentUser;

  /// UID utente corrente
  String? get currentUserId => _auth.currentUser?.uid;

  /// Login anonimo
  Future<UserCredential> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    await _createUserDocument(credential.user!);
    return credential;
  }

  /// Login con email e password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _updateLastLogin(credential.user!.uid);
    return credential;
  }

  /// Registrazione con email e password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (displayName != null) {
      await credential.user!.updateDisplayName(displayName);
    }
    
    await _createUserDocument(credential.user!);
    return credential;
  }

  /// Collega account anonimo a email
  Future<UserCredential> linkAnonymousToEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    
    final userCredential = await _auth.currentUser!.linkWithCredential(credential);
    
    // Aggiorna il documento utente
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userCredential.user!.uid)
        .update({
          'email': email,
          'isAnonymous': false,
        });
    
    return userCredential;
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Elimina account
  Future<void> deleteAccount() async {
    final userId = currentUserId;
    if (userId == null) return;

    // Elimina dati utente da Firestore
    await _deleteUserData(userId);
    
    // Elimina account Firebase
    await _auth.currentUser?.delete();
  }

  /// Crea documento utente in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);
    
    final exists = await userDoc.get();
    if (!exists.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isAnonymous: user.isAnonymous,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      await userDoc.set(userModel.toFirestore());
    }
  }

  /// Aggiorna ultimo login
  Future<void> _updateLastLogin(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
  }

  /// Elimina tutti i dati utente
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();
    
    // Elimina rientri
    final rientri = await _firestore
        .collection(AppConstants.rientriCollection)
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in rientri.docs) {
      batch.delete(doc.reference);
    }
    
    // Elimina contatti
    final contacts = await _firestore
        .collection(AppConstants.contactsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in contacts.docs) {
      batch.delete(doc.reference);
    }
    
    // Elimina documento utente
    batch.delete(_firestore
        .collection(AppConstants.usersCollection)
        .doc(userId));
    
    await batch.commit();
  }

  /// Aggiorna FCM token
  Future<void> updateFcmToken(String token) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  /// Ottieni profilo utente
  Future<UserModel?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream del profilo utente
  Stream<UserModel?> getUserProfileStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);
    
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Aggiorna impostazioni utente
  Future<void> updateUserSettings(UserSettings settings) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'settings': settings.toMap()});
  }
}

