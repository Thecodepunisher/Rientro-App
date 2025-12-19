/**
 * RIENTRO - Cloud Functions
 * 
 * Architettura event-driven per il monitoraggio dei rientri.
 * Niente polling, solo trigger su eventi Firestore.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ═══════════════════════════════════════════════════════════════════════════
// COSTANTI
// ═══════════════════════════════════════════════════════════════════════════

const COLLECTIONS = {
  users: "users",
  rientri: "rientri",
  contacts: "contacts",
  notifications: "notifications",
} as const;

const ESCALATION_LEVELS = {
  NONE: 0,
  SOFT: 1,      // Prima notifica soft all'utente
  URGENT: 2,    // Seconda notifica più urgente
  EMERGENCY: 3, // Notifica ai contatti di emergenza
  SOS: 4,       // SOS manuale attivato
} as const;

const RIENTRO_STATUS = {
  ACTIVE: "active",
  LATE: "late",
  EMERGENCY: "emergency",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
} as const;

// Tempi in minuti
const TIMING = {
  CHECK_INTERVAL: 15,      // Intervallo tra i check
  GRACE_PERIOD: 5,         // Tempo di tolleranza prima di escalation
  ESCALATION_DELAY: 10,    // Delay tra livelli di escalation
} as const;

// ═══════════════════════════════════════════════════════════════════════════
// TRIGGER: NUOVO RIENTRO CREATO
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Quando viene creato un nuovo rientro:
 * 1. Schedula il primo check
 * 2. Notifica i contatti di emergenza
 */
export const onRientroCreated = functions.firestore
  .document(`${COLLECTIONS.rientri}/{rientroId}`)
  .onCreate(async (snapshot, context) => {
    const rientro = snapshot.data();
    const rientroId = context.params.rientroId;

    functions.logger.info(`Nuovo rientro creato: ${rientroId}`, { rientro });

    try {
      // Ottieni info utente
      const userDoc = await db.collection(COLLECTIONS.users)
        .doc(rientro.userId)
        .get();
      const user = userDoc.data();
      const userName = user?.displayName || user?.email?.split("@")[0] || "Un utente";

      // Notifica i contatti di emergenza dell'inizio rientro
      if (rientro.contactIds && rientro.contactIds.length > 0) {
        await notifyContacts(
          rientro.contactIds,
          {
            title: "Rientro avviato",
            body: `${userName} ha avviato un rientro e ti ha aggiunto come contatto di emergenza.`,
            type: "rientro_started",
            rientroId: rientroId,
            userId: rientro.userId,
            userName: userName,
          },
          rientro.silentMode
        );
      }

      // Schedula il primo check (dopo l'intervallo standard)
      await scheduleCheck(rientroId, TIMING.CHECK_INTERVAL);

    } catch (error) {
      functions.logger.error("Errore in onRientroCreated:", error);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// TRIGGER: AGGIORNAMENTO RIENTRO
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Quando un rientro viene aggiornato:
 * - Se status cambia a emergency → notifica contatti
 * - Se status cambia a completed → notifica completamento
 * - Se viene fatto un check-in → reset escalation timer
 */
export const onRientroUpdated = functions.firestore
  .document(`${COLLECTIONS.rientri}/{rientroId}`)
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const rientroId = context.params.rientroId;

    try {
      // Ottieni info utente
      const userDoc = await db.collection(COLLECTIONS.users)
        .doc(after.userId)
        .get();
      const user = userDoc.data();
      const userName = user?.displayName || user?.email?.split("@")[0] || "Un utente";

      // Status cambiato a EMERGENCY
      if (before.status !== RIENTRO_STATUS.EMERGENCY && 
          after.status === RIENTRO_STATUS.EMERGENCY) {
        
        const isSOS = after.escalationLevel === ESCALATION_LEVELS.SOS;
        
        await notifyContacts(
          after.contactIds,
          {
            title: isSOS ? "🆘 SOS ATTIVATO" : "⚠️ EMERGENZA",
            body: isSOS 
              ? `${userName} ha attivato manualmente il segnale di emergenza.`
              : `${userName} potrebbe aver bisogno di aiuto. Non risponde da tempo.`,
            type: isSOS ? "sos" : "emergency",
            rientroId: rientroId,
            userId: after.userId,
            userName: userName,
            location: after.lastKnownLocation,
          },
          false // Mai silenzioso per emergenze
        );
      }

      // Status cambiato a COMPLETED
      if (before.status !== RIENTRO_STATUS.COMPLETED && 
          after.status === RIENTRO_STATUS.COMPLETED) {
        
        await notifyContacts(
          after.contactIds,
          {
            title: "Rientro completato ✓",
            body: `${userName} è arrivato a destinazione in sicurezza.`,
            type: "rientro_completed",
            rientroId: rientroId,
            userId: after.userId,
            userName: userName,
          },
          after.silentMode
        );
      }

      // Check-in ricevuto → reset timer
      if (after.lastCheckIn?.toDate?.() > before.lastCheckIn?.toDate?.()) {
        functions.logger.info(`Check-in ricevuto per rientro ${rientroId}`);
        // Il prossimo check verrà schedulato dal sistema
      }

    } catch (error) {
      functions.logger.error("Errore in onRientroUpdated:", error);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED FUNCTION: CHECK RIENTRI ATTIVI
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Funzione schedulata che controlla tutti i rientri attivi.
 * Eseguita ogni 5 minuti.
 */
export const checkActiveRientri = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    functions.logger.info("Avvio check rientri attivi");

    try {
      const now = admin.firestore.Timestamp.now();
      
      // Query per rientri attivi o in ritardo
      const activeRientri = await db.collection(COLLECTIONS.rientri)
        .where("status", "in", [RIENTRO_STATUS.ACTIVE, RIENTRO_STATUS.LATE])
        .get();

      for (const doc of activeRientri.docs) {
        await processRientroCheck(doc.id, doc.data(), now);
      }

      functions.logger.info(`Controllati ${activeRientri.size} rientri`);

    } catch (error) {
      functions.logger.error("Errore in checkActiveRientri:", error);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// FUNZIONI HELPER
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Processa il check di un singolo rientro
 */
async function processRientroCheck(
  rientroId: string, 
  rientro: FirebaseFirestore.DocumentData,
  now: admin.firestore.Timestamp
): Promise<void> {
  const expectedEndTime = rientro.expectedEndTime.toDate();
  const lastPing = rientro.lastPing?.toDate();
  const currentTime = now.toDate();
  
  // Calcola minuti dal'ultimo ping
  const minutesSinceLastPing = lastPing 
    ? Math.floor((currentTime.getTime() - lastPing.getTime()) / 60000)
    : Infinity;
  
  // Calcola minuti di ritardo
  const minutesLate = Math.max(0, 
    Math.floor((currentTime.getTime() - expectedEndTime.getTime()) / 60000)
  );

  functions.logger.info(`Check rientro ${rientroId}:`, {
    minutesSinceLastPing,
    minutesLate,
    currentEscalation: rientro.escalationLevel,
    silentMode: rientro.silentMode,
  });

  // Determina il nuovo livello di escalation
  let newEscalation = rientro.escalationLevel || 0;
  let newStatus = rientro.status;

  // Logica di escalation basata su ritardo e mancanza di risposta
  if (minutesLate > 0) {
    // Il rientro è in ritardo
    if (newStatus === RIENTRO_STATUS.ACTIVE) {
      newStatus = RIENTRO_STATUS.LATE;
    }

    // Nessuna risposta per troppo tempo → escalation
    if (minutesSinceLastPing > TIMING.CHECK_INTERVAL + TIMING.GRACE_PERIOD) {
      if (newEscalation < ESCALATION_LEVELS.SOFT) {
        newEscalation = ESCALATION_LEVELS.SOFT;
      } else if (minutesSinceLastPing > TIMING.CHECK_INTERVAL * 2 + TIMING.ESCALATION_DELAY) {
        if (newEscalation < ESCALATION_LEVELS.URGENT) {
          newEscalation = ESCALATION_LEVELS.URGENT;
        }
      }
      
      // Escalation finale → emergenza
      if (minutesSinceLastPing > TIMING.CHECK_INTERVAL * 3 + TIMING.ESCALATION_DELAY * 2) {
        if (newEscalation < ESCALATION_LEVELS.EMERGENCY) {
          newEscalation = ESCALATION_LEVELS.EMERGENCY;
          newStatus = RIENTRO_STATUS.EMERGENCY;
        }
      }
    }
  }

  // Aggiorna se necessario
  if (newEscalation !== rientro.escalationLevel || newStatus !== rientro.status) {
    await db.collection(COLLECTIONS.rientri).doc(rientroId).update({
      escalationLevel: newEscalation,
      status: newStatus,
    });

    // Se non siamo ancora in emergenza e non in modalità silenziosa,
    // invia notifica soft all'utente
    if (newEscalation > 0 && newEscalation < ESCALATION_LEVELS.EMERGENCY) {
      await sendCheckInReminder(rientro.userId, rientroId, rientro.silentMode);
    }
  }
}

/**
 * Invia promemoria check-in all'utente
 */
async function sendCheckInReminder(
  userId: string, 
  rientroId: string,
  silentMode: boolean
): Promise<void> {
  if (silentMode) return;

  const userDoc = await db.collection(COLLECTIONS.users).doc(userId).get();
  const fcmToken = userDoc.data()?.fcmToken;
  
  if (!fcmToken) return;

  try {
    await messaging.send({
      token: fcmToken,
      notification: {
        title: "Tutto ok?",
        body: "Non ti sentiamo da un po'. Conferma che stai bene.",
      },
      data: {
        type: "check_in",
        rientroId: rientroId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "rientro_checkin",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
  } catch (error) {
    functions.logger.error("Errore invio notifica check-in:", error);
  }
}

/**
 * Notifica i contatti di emergenza
 */
async function notifyContacts(
  contactIds: string[],
  payload: {
    title: string;
    body: string;
    type: string;
    rientroId: string;
    userId: string;
    userName: string;
    location?: FirebaseFirestore.GeoPoint;
  },
  silentMode: boolean
): Promise<void> {
  // Per emergenze, non rispettare mai il silentMode
  const isEmergency = payload.type === "emergency" || payload.type === "sos";
  
  if (silentMode && !isEmergency) return;

  for (const contactId of contactIds) {
    try {
      const contactDoc = await db.collection(COLLECTIONS.contacts)
        .doc(contactId)
        .get();
      
      const contact = contactDoc.data();
      if (!contact) continue;

      // Se il contatto ha l'app installata, invia push
      if (contact.fcmToken) {
        const locationData = payload.location ? {
          lat: payload.location.latitude.toString(),
          lng: payload.location.longitude.toString(),
          mapsUrl: `https://www.google.com/maps/search/?api=1&query=${payload.location.latitude},${payload.location.longitude}`,
        } : {};

        await messaging.send({
          token: contact.fcmToken,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: {
            type: payload.type,
            rientroId: payload.rientroId,
            userId: payload.userId,
            userName: payload.userName,
            ...locationData,
          },
          android: {
            priority: "high",
            notification: {
              channelId: isEmergency ? "rientro_emergency" : "rientro_default",
              priority: isEmergency ? "max" : "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: isEmergency ? "critical" : "default",
                badge: 1,
                "content-available": 1,
              },
            },
            headers: isEmergency ? {
              "apns-priority": "10",
            } : undefined,
          },
        });
      }

      // Registra notifica inviata
      await db.collection(COLLECTIONS.notifications).add({
        contactId: contactId,
        rientroId: payload.rientroId,
        type: payload.type,
        title: payload.title,
        body: payload.body,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        delivered: !!contact.fcmToken,
      });

      // Aggiorna lastNotifiedAt sul contatto
      await contactDoc.ref.update({
        lastNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      functions.logger.error(`Errore notifica contatto ${contactId}:`, error);
    }
  }
}

/**
 * Schedula un check futuro (placeholder - in produzione usare Cloud Tasks)
 */
async function scheduleCheck(rientroId: string, delayMinutes: number): Promise<void> {
  // In una implementazione completa, si userebbe Cloud Tasks
  // Per ora, i check vengono gestiti dalla funzione schedulata
  functions.logger.info(`Check schedulato per rientro ${rientroId} tra ${delayMinutes} minuti`);
}

// ═══════════════════════════════════════════════════════════════════════════
// CLEANUP: ELIMINA DATI VECCHI
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Funzione schedulata giornaliera per cleanup dati vecchi
 */
export const cleanupOldData = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    functions.logger.info("Avvio cleanup dati vecchi");

    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 giorni fa
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

      // Elimina rientri completati/annullati vecchi
      const oldRientri = await db.collection(COLLECTIONS.rientri)
        .where("status", "in", [RIENTRO_STATUS.COMPLETED, RIENTRO_STATUS.CANCELLED])
        .where("actualEndTime", "<", cutoffTimestamp)
        .get();

      const batch = db.batch();
      oldRientri.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // Elimina notifiche vecchie
      const oldNotifications = await db.collection(COLLECTIONS.notifications)
        .where("sentAt", "<", cutoffTimestamp)
        .get();

      oldNotifications.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      functions.logger.info(`Eliminati ${oldRientri.size} rientri e ${oldNotifications.size} notifiche`);

    } catch (error) {
      functions.logger.error("Errore in cleanupOldData:", error);
    }
  });

