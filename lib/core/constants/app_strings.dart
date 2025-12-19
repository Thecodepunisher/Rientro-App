/// Stringhe localizzate dell'applicazione
class AppStrings {
  AppStrings._();
  
  // General
  static const String appName = 'RIENTRO';
  static const String loading = 'Caricamento...';
  static const String error = 'Si è verificato un errore';
  static const String retry = 'Riprova';
  static const String cancel = 'Annulla';
  static const String confirm = 'Conferma';
  static const String save = 'Salva';
  static const String delete = 'Elimina';
  static const String close = 'Chiudi';
  static const String done = 'Fatto';
  static const String next = 'Avanti';
  static const String back = 'Indietro';
  
  // Auth
  static const String welcome = 'Benvenuto';
  static const String welcomeSubtitle = 'Il tuo rientro, sotto controllo';
  static const String continueAnonymously = 'Continua senza account';
  static const String signInWithEmail = 'Accedi con email';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String signIn = 'Accedi';
  static const String signUp = 'Registrati';
  static const String forgotPassword = 'Password dimenticata?';
  
  // Home
  static const String homeTitle = 'RIENTRO';
  static const String startRientro = 'Avvia rientro';
  static const String noActiveRientro = 'Nessun rientro attivo';
  static const String safeMessage = 'Sei al sicuro';
  static const String lastRientro = 'Ultimo rientro';
  
  // Rientro
  static const String newRientro = 'Nuovo rientro';
  static const String selectContacts = 'Seleziona contatti';
  static const String selectDestination = 'Destinazione';
  static const String estimatedDuration = 'Durata stimata';
  static const String startNow = 'Avvia ora';
  static const String rientroActive = 'Rientro in corso';
  static const String rientroLate = 'Sei in ritardo';
  static const String rientroEmergency = 'Emergenza attiva';
  static const String imOk = 'Sto bene';
  static const String arrived = 'Sono arrivato';
  static const String cancelRientro = 'Annulla rientro';
  static const String confirmCancel = 'Sei sicuro di voler annullare?';
  
  // Status Messages
  static const String statusActive = 'In viaggio';
  static const String statusLate = 'Ritardo rilevato';
  static const String statusEmergency = 'I tuoi contatti sono stati avvisati';
  static const String statusCompleted = 'Arrivato a destinazione';
  
  // SOS
  static const String sosButton = 'SOS';
  static const String sosActivated = 'SOS attivato';
  static const String sosMessage = 'I tuoi contatti di emergenza sono stati avvisati con la tua posizione.';
  static const String sosConfirm = 'Conferma emergenza';
  static const String sosCancel = 'Era un errore';
  
  // Contacts
  static const String emergencyContacts = 'Contatti di emergenza';
  static const String addContact = 'Aggiungi contatto';
  static const String editContact = 'Modifica contatto';
  static const String contactName = 'Nome';
  static const String contactPhone = 'Telefono';
  static const String contactEmail = 'Email (opzionale)';
  static const String noContacts = 'Nessun contatto di emergenza';
  static const String addContactHint = 'Aggiungi almeno un contatto per iniziare';
  
  // Settings
  static const String settings = 'Impostazioni';
  static const String silentMode = 'Modalità silenziosa';
  static const String silentModeDescription = 'Le notifiche non saranno visibili, ma il monitoraggio continua';
  static const String notifications = 'Notifiche';
  static const String privacy = 'Privacy';
  static const String deleteAccount = 'Elimina account';
  static const String signOut = 'Esci';
  static const String about = 'Informazioni';
  static const String version = 'Versione';
  
  // Notifications (for emergency contacts)
  static const String notifRientroStartedTitle = 'Rientro avviato';
  static String notifRientroStartedBody(String name) => 
    '$name ha avviato un rientro e ti ha aggiunto come contatto di emergenza.';
  
  static const String notifLateTitle = 'Possibile ritardo';
  static String notifLateBody(String name) => 
    '$name potrebbe essere in ritardo. Nessuna risposta ricevuta.';
  
  static const String notifEmergencyTitle = '⚠️ EMERGENZA';
  static String notifEmergencyBody(String name) => 
    '$name potrebbe aver bisogno di aiuto. Non risponde da tempo.';
  
  static const String notifSOSTitle = '🆘 SOS ATTIVATO';
  static String notifSOSBody(String name) => 
    '$name ha attivato manualmente il segnale di emergenza.';
  
  static const String notifCompletedTitle = 'Rientro completato';
  static String notifCompletedBody(String name) => 
    '$name è arrivato a destinazione in sicurezza.';
  
  // Errors
  static const String errorGeneric = 'Qualcosa è andato storto';
  static const String errorNetwork = 'Controlla la connessione internet';
  static const String errorLocation = 'Impossibile ottenere la posizione';
  static const String errorPermission = 'Permesso necessario';
  static const String errorNoContacts = 'Aggiungi almeno un contatto di emergenza';
  
  // Permissions
  static const String permissionLocation = 'Accesso alla posizione';
  static const String permissionLocationRationale = 
    'RIENTRO ha bisogno della tua posizione per monitorare il tuo viaggio e avvisare i tuoi contatti in caso di emergenza.';
  static const String permissionNotifications = 'Notifiche';
  static const String permissionNotificationsRationale = 
    'Le notifiche ti permettono di ricevere avvisi durante il rientro.';
  static const String permissionContacts = 'Accesso ai contatti';
  static const String permissionContactsRationale = 
    'Per selezionare facilmente i contatti di emergenza dalla tua rubrica.';
  
  // Time
  static String minutesAgo(int minutes) => '$minutes min fa';
  static String hoursAgo(int hours) => '$hours ore fa';
  static String estimatedArrival(String time) => 'Arrivo stimato: $time';
  static String duration(int minutes) => '$minutes minuti';
  static String durationHours(int hours, int minutes) => 
    '${hours}h ${minutes}m';
}

