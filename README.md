# RIENTRO

**App di sicurezza personale per monitorare i tuoi spostamenti**

RIENTRO è un'applicazione mobile che monitora un "rientro" (percorso verso casa o destinazione) e avvisa automaticamente i contatti di emergenza in caso di anomalie, anche quando l'utente non può intervenire.

---

## 🎯 Filosofia

> *Non stai costruendo "un'app". Stai costruendo qualcosa che deve funzionare quando l'utente non può.*

**Principi fondamentali:**
- L'app deve funzionare anche nel silenzio
- Deve richiedere il minimo sforzo cognitivo
- Deve sembrare affidabile, discreta, di sistema
- UX semplice, UI premium, nessuna feature inutile

---

## ✨ Funzionalità Principali

### Per l'Utente
- **🚀 Avvio Rientro** - Una sola azione per iniziare il monitoraggio
- **📍 Monitoraggio Attivo** - Tracking della posizione durante il viaggio
- **✅ Check-in** - Conferma che stai bene con un tap
- **🆘 SOS** - Pulsante sempre accessibile per emergenze
- **🔇 Modalità Silenziosa** - Monitoraggio discreto senza notifiche visibili
- **🏠 Arrivo** - Conferma di essere arrivati a destinazione

### Per i Contatti di Emergenza
- **📩 Notifiche chiare** - Messaggi comprensibili in < 3 secondi
- **🗺️ Posizione** - Link diretto alla mappa
- **📞 Chiamata rapida** - Contatto immediato

---

## 🏗️ Architettura

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App configuration
├── core/
│   ├── constants/            # App constants, strings
│   ├── theme/                # Design system
│   ├── utils/                # Utilities (haptics, etc.)
│   └── extensions/           # Context extensions
├── features/
│   ├── auth/                 # Authentication
│   ├── home/                 # Home screen
│   ├── rientro/              # Journey monitoring
│   ├── contacts/             # Emergency contacts
│   ├── settings/             # App settings
│   └── sos/                  # Emergency features
├── models/                   # Data models
├── services/                 # Firebase services
├── providers/                # Riverpod providers
└── widgets/                  # Shared widgets

firebase/
├── functions/                # Cloud Functions (TypeScript)
├── firestore.rules           # Security rules
├── firestore.indexes.json    # Database indexes
└── firebase.json             # Firebase config
```

---

## 🛠️ Stack Tecnologico

### Frontend
- **Flutter** (ultima stable)
- **Riverpod** - State management
- **Material 3 + Cupertino** - Platform adaptive UI
- **flutter_animate** - Animazioni fluide

### Backend
- **Firebase Authentication** - Email + Anonimo
- **Cloud Firestore** - Database real-time
- **Cloud Functions** - Logic server-side (TypeScript)
- **Firebase Cloud Messaging** - Push notifications

### Design
- **Dark-first** - Tema scuro di default
- **Accent color**: Verde sicurezza (#34C759)
- **Tipografia**: SF Pro inspired
- **Animazioni**: Haptic feedback + micro-interactions

---

## 📦 Setup & Installazione

### Prerequisiti
- Flutter SDK >= 3.2.0
- Firebase CLI
- Node.js >= 18 (per Cloud Functions)

### 1. Clone e Dipendenze

```bash
# Clone del repository
git clone [repository-url]
cd rientro

# Installa dipendenze Flutter
flutter pub get

# Installa dipendenze Cloud Functions
cd firebase/functions
npm install
cd ../..
```

### 2. Configurazione Firebase

```bash
# Login Firebase
firebase login

# Crea progetto Firebase
firebase projects:create rientro-app

# Configura FlutterFire
flutterfire configure
```

### 3. Deploy Backend

```bash
# Deploy Firestore rules e indexes
firebase deploy --only firestore

# Deploy Cloud Functions
firebase deploy --only functions
```

### 4. Build & Run

```bash
# iOS
flutter build ios

# Android
flutter build apk

# Development
flutter run
```

---

## 📊 Database Schema

### users/{userId}
```javascript
{
  uid: string,
  email: string?,
  displayName: string?,
  phoneNumber: string?,
  isAnonymous: boolean,
  createdAt: timestamp,
  lastLoginAt: timestamp?,
  fcmToken: string?,
  settings: {
    silentModeDefault: boolean,
    defaultDurationMinutes: number,
    autoLocationEnabled: boolean,
    shakeForSOSEnabled: boolean,
    defaultContactIds: string[]
  }
}
```

### rientri/{rientroId}
```javascript
{
  userId: string,
  status: 'active' | 'late' | 'emergency' | 'completed' | 'cancelled',
  startTime: timestamp,
  expectedEndTime: timestamp,
  actualEndTime: timestamp?,
  startLocation: geopoint?,
  destinationLocation: geopoint?,
  destinationName: string?,
  lastKnownLocation: geopoint?,
  lastPing: timestamp?,
  lastCheckIn: timestamp?,
  silentMode: boolean,
  escalationLevel: number, // 0-4
  contactIds: string[],
  batteryLevel: number?,
  isConnected: boolean?
}
```

### contacts/{contactId}
```javascript
{
  userId: string, // proprietario
  name: string,
  phoneNumber: string,
  email: string?,
  fcmToken: string?, // se ha l'app
  isPrimary: boolean,
  createdAt: timestamp,
  lastNotifiedAt: timestamp?
}
```

---

## 🔒 Sicurezza & Privacy

- **Niente tracking continuo** - Posizione solo durante rientri attivi
- **Dati temporanei** - Eliminazione automatica dopo 30 giorni
- **Principio "least data possible"** - Solo dati necessari
- **Security Rules restrittive** - Accesso solo ai propri dati
- **Crittografia** - Dati in transito e a riposo

---

## 🔄 Escalation Flow

```
┌─────────────────────────────────────────────────────────────┐
│  START RIENTRO                                              │
│    ↓                                                        │
│  ACTIVE (status)                                            │
│    ↓                                                        │
│  [Check ogni 15 min]                                        │
│    ↓                                                        │
│  Nessuna risposta?                                          │
│    ↓                                                        │
│  Level 1 (SOFT) → Notifica utente "Tutto ok?"               │
│    ↓                                                        │
│  Ancora nessuna risposta (+10 min)?                         │
│    ↓                                                        │
│  Level 2 (URGENT) → Notifica più urgente                    │
│    ↓                                                        │
│  Ancora nessuna risposta (+10 min)?                         │
│    ↓                                                        │
│  Level 3 (EMERGENCY) → Notifica contatti emergenza          │
│    ↓                                                        │
│  Status → EMERGENCY                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  SOS MANUALE                                                │
│    ↓                                                        │
│  Level 4 (SOS) → Notifica immediata contatti                │
│    ↓                                                        │
│  Status → EMERGENCY                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 Design System

### Colori
| Nome | Hex | Uso |
|------|-----|-----|
| Background | `#0A0A0A` | Sfondo principale |
| Surface | `#141414` | Card, elementi |
| Accent | `#34C759` | CTA, successo |
| Warning | `#FFD60A` | Attenzione |
| Error | `#FF453A` | Errore, SOS |
| Text Primary | `#FFFFFF` | Testo principale |
| Text Secondary | `#8E8E93` | Testo secondario |

### Tipografia
- **Display**: Bold, tracking largo per titoli hero
- **Body**: Regular, leggibile per contenuto
- **Label**: Semibold per bottoni e badge

### Spacing
Sistema 8pt: 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64

### Border Radius
- Small: 8px
- Medium: 12px
- Large: 16px
- XLarge: 24px

---

## 🧪 Edge Cases Gestiti

- ❌ Perdita connessione
- ❌ Batteria bassa/critica
- ❌ App in background
- ❌ Utente non risponde
- ❌ Falsi positivi
- ❌ Chiusura forzata app

> **Il silenzio è un segnale, non un bug.**

---

## 📱 Configurazione iOS

Aggiungi in `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>RIENTRO usa la tua posizione per monitorare il viaggio e avvisare i contatti in caso di emergenza.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RIENTRO usa la tua posizione per monitorare il viaggio anche quando l'app è in background.</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>location</string>
    <string>remote-notification</string>
</array>
```

## 📱 Configurazione Android

Aggiungi in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## 📄 License

MIT License - vedi [LICENSE](LICENSE) per dettagli.

---

## 🤝 Contributing

Contribuzioni benvenute! Per favore leggi le [guidelines](CONTRIBUTING.md) prima di aprire una PR.

---

**Built with ❤️ for personal safety**
