import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rientro/models/emergency_contact_model.dart';
import 'package:rientro/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Servizio per gestione contatti di emergenza
class ContactsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _firestore.collection(AppConstants.contactsCollection);

  /// Aggiungi contatto di emergenza
  /// 
  /// NOTA: La gestione del flag "primary" (rimozione dagli altri contatti)
  /// è stata spostata nel provider per mantenere il service privo di logica di business.
  /// Se isPrimary=true, il chiamante deve prima chiamare removePrimaryFromOthers().
  Future<EmergencyContactModel> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    String? email,
    bool isPrimary = false,
  }) async {
    final id = _uuid.v4();
    
    final contact = createEmergencyContact(
      id: id,
      userId: userId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      isPrimary: isPrimary,
    );

    await _contactsRef.doc(id).set(contact.toFirestore());
    return contact;
  }
  
  /// Rimuovi flag primary da tutti i contatti dell'utente
  /// 
  /// Metodo pubblico per permettere al provider di gestire la logica "primary".
  Future<void> removePrimaryFromOthers(String userId) async {
    await _removePrimaryFlag(userId);
  }

  /// Ottieni tutti i contatti dell'utente
  Future<List<EmergencyContactModel>> getContacts(String userId) async {
    final query = await _contactsRef
        .where('userId', isEqualTo: userId)
        .orderBy('isPrimary', descending: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => EmergencyContactModel.fromFirestore(doc))
        .toList();
  }

  /// Stream dei contatti
  Stream<List<EmergencyContactModel>> getContactsStream(String userId) {
    return _contactsRef
        .where('userId', isEqualTo: userId)
        .orderBy('isPrimary', descending: true)
        .orderBy('name')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => EmergencyContactModel.fromFirestore(doc))
            .toList());
  }

  /// Ottieni contatto singolo
  Future<EmergencyContactModel?> getContact(String contactId) async {
    final doc = await _contactsRef.doc(contactId).get();
    if (!doc.exists) return null;
    return EmergencyContactModel.fromFirestore(doc);
  }

  /// Aggiorna contatto
  /// 
  /// NOTA: Se isPrimary=true, il chiamante deve prima chiamare removePrimaryFromOthers()
  /// per mantenere la logica di business nel provider.
  Future<void> updateContact(
    String contactId, {
    String? name,
    String? phoneNumber,
    String? email,
    bool? isPrimary,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (email != null) data['email'] = email;
    if (isPrimary != null) data['isPrimary'] = isPrimary;

    if (data.isNotEmpty) {
      await _contactsRef.doc(contactId).update(data);
    }
  }

  /// Elimina contatto
  Future<void> deleteContact(String contactId) async {
    await _contactsRef.doc(contactId).delete();
  }

  /// Ottieni contatti per IDs
  Future<List<EmergencyContactModel>> getContactsByIds(
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) return [];
    
    // Firestore limita whereIn a 10 elementi
    final chunks = <List<String>>[];
    for (var i = 0; i < contactIds.length; i += 10) {
      chunks.add(contactIds.sublist(
        i,
        i + 10 > contactIds.length ? contactIds.length : i + 10,
      ));
    }

    final results = <EmergencyContactModel>[];
    for (final chunk in chunks) {
      final query = await _contactsRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        query.docs.map((doc) => EmergencyContactModel.fromFirestore(doc)),
      );
    }
    
    return results;
  }

  /// Conta contatti utente
  Future<int> getContactsCount(String userId) async {
    final query = await _contactsRef
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return query.count ?? 0;
  }

  /// Aggiorna FCM token di un contatto (se ha l'app)
  Future<void> updateContactFcmToken(
    String contactId,
    String fcmToken,
  ) async {
    await _contactsRef.doc(contactId).update({
      'fcmToken': fcmToken,
    });
  }

  /// Registra ultima notifica inviata
  Future<void> markNotified(String contactId) async {
    await _contactsRef.doc(contactId).update({
      'lastNotifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rimuovi flag primary da tutti i contatti dell'utente
  Future<void> _removePrimaryFlag(String userId) async {
    final query = await _contactsRef
        .where('userId', isEqualTo: userId)
        .where('isPrimary', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isPrimary': false});
    }
    await batch.commit();
  }
}

