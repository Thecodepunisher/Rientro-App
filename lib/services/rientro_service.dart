import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rientro/models/rientro_model.dart';
import 'package:rientro/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Servizio per gestione rientri
class RientroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _rientriRef =>
      _firestore.collection(AppConstants.rientriCollection);

  /// Crea un nuovo rientro
  Future<RientroModel> createRientro({
    required String userId,
    required int durationMinutes,
    required List<String> contactIds,
    GeoPoint? startLocation,
    GeoPoint? destinationLocation,
    String? destinationName,
    bool silentMode = false,
  }) async {
    final id = _uuid.v4();
    final rientro = createNewRientro(
      id: id,
      userId: userId,
      durationMinutes: durationMinutes,
      contactIds: contactIds,
      startLocation: startLocation,
      destinationLocation: destinationLocation,
      destinationName: destinationName,
      silentMode: silentMode,
    );

    await _rientriRef.doc(id).set(rientro.toFirestore());
    return rientro;
  }

  /// Ottieni rientro per ID
  Future<RientroModel?> getRientro(String rientroId) async {
    final doc = await _rientriRef.doc(rientroId).get();
    if (!doc.exists) return null;
    return RientroModel.fromFirestore(doc);
  }

  /// Stream di un rientro specifico
  Stream<RientroModel?> getRientroStream(String rientroId) {
    return _rientriRef
        .doc(rientroId)
        .snapshots()
        .map((doc) => doc.exists ? RientroModel.fromFirestore(doc) : null);
  }

  /// Ottieni rientro attivo per utente
  Future<RientroModel?> getActiveRientro(String userId) async {
    final query = await _rientriRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'late', 'emergency'])
        .orderBy('startTime', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return RientroModel.fromFirestore(query.docs.first);
  }

  /// Stream del rientro attivo
  Stream<RientroModel?> getActiveRientroStream(String userId) {
    return _rientriRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'late', 'emergency'])
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) return null;
          return RientroModel.fromFirestore(query.docs.first);
        });
  }

  /// Storico rientri
  Future<List<RientroModel>> getRientroHistory(
    String userId, {
    int limit = 20,
  }) async {
    final query = await _rientriRef
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => RientroModel.fromFirestore(doc)).toList();
  }

  /// Aggiorna ping (utente conferma che sta bene)
  Future<void> updatePing(String rientroId, {GeoPoint? location}) async {
    final data = <String, dynamic>{
      'lastPing': FieldValue.serverTimestamp(),
      'lastCheckIn': FieldValue.serverTimestamp(),
    };
    
    if (location != null) {
      data['lastKnownLocation'] = location;
    }

    await _rientriRef.doc(rientroId).update(data);
  }

  /// Aggiorna posizione
  Future<void> updateLocation(String rientroId, GeoPoint location) async {
    await _rientriRef.doc(rientroId).update({
      'lastKnownLocation': location,
      'lastPing': FieldValue.serverTimestamp(),
    });
  }

  /// Aggiorna stato batteria/connessione
  /// 
  /// NOTA: Questo metodo aggiorna SOLO i dati. La decisione di quando aggiornare
  /// (frequenza, threshold, ecc.) è responsabilità del provider.
  /// 
  /// PUNTO FRAGILE: Se chiamato troppo spesso, può generare molte scritture Firestore.
  /// Il provider dovrebbe limitare la frequenza o aggiornare solo se i valori cambiano significativamente.
  Future<void> updateDeviceStatus(
    String rientroId, {
    int? batteryLevel,
    bool? isConnected,
  }) async {
    final data = <String, dynamic>{};
    if (batteryLevel != null) data['batteryLevel'] = batteryLevel;
    if (isConnected != null) data['isConnected'] = isConnected;
    
    if (data.isNotEmpty) {
      await _rientriRef.doc(rientroId).update(data);
    }
  }

  /// Cambia stato rientro
  Future<void> updateStatus(String rientroId, RientroStatus status) async {
    final data = <String, dynamic>{
      'status': status.value,
    };
    
    if (status.isClosed) {
      data['actualEndTime'] = FieldValue.serverTimestamp();
    }

    await _rientriRef.doc(rientroId).update(data);
  }

  /// Attiva SOS
  /// 
  /// NOTA: Questo metodo aggiorna SOLO i dati del rientro.
  /// Il provider che chiama questo metodo deve decidere escalationLevel e status.
  /// Questo mantiene il service privo di logica di business.
  Future<void> activateSOS(
    String rientroId, {
    GeoPoint? location,
    int escalationLevel = AppConstants.escalationLevelSOS,
  }) async {
    final data = <String, dynamic>{
      'status': RientroStatus.emergency.value,
      'escalationLevel': escalationLevel,
    };
    
    if (location != null) {
      data['lastKnownLocation'] = location;
    }

    await _rientriRef.doc(rientroId).update(data);
  }

  /// Completa rientro (arrivo)
  Future<void> completeRientro(String rientroId) async {
    await _rientriRef.doc(rientroId).update({
      'status': RientroStatus.completed.value,
      'actualEndTime': FieldValue.serverTimestamp(),
    });
  }

  /// Annulla rientro
  Future<void> cancelRientro(String rientroId) async {
    await _rientriRef.doc(rientroId).update({
      'status': RientroStatus.cancelled.value,
      'actualEndTime': FieldValue.serverTimestamp(),
    });
  }

  /// Aggiorna livello escalation
  /// 
  /// NOTA: Questo metodo aggiorna SOLO il livello escalation.
  /// La decisione di cambiare lo status in base al livello deve essere presa
  /// dal provider che chiama questo metodo. Il service non deve contenere
  /// logica di business.
  Future<void> updateEscalationLevel(String rientroId, int level) async {
    await _rientriRef.doc(rientroId).update({
      'escalationLevel': level,
    });
  }
  
  /// Aggiorna escalation level e status insieme
  /// 
  /// Usa questo metodo quando devi aggiornare entrambi in modo atomico.
  /// Il provider decide quale status associare al livello escalation.
  Future<void> updateEscalationLevelAndStatus(
    String rientroId,
    int level,
    RientroStatus status,
  ) async {
    await _rientriRef.doc(rientroId).update({
      'escalationLevel': level,
      'status': status.value,
    });
  }

  /// Elimina rientro (solo per cleanup)
  Future<void> deleteRientro(String rientroId) async {
    await _rientriRef.doc(rientroId).delete();
  }

  /// Cleanup rientri vecchi completati (> 30 giorni)
  Future<void> cleanupOldRientri(String userId) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final query = await _rientriRef
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .where('actualEndTime', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

