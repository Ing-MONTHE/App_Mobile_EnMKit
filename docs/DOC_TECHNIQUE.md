# Documentation technique — EnMKit

Application Flutter de pilotage de **kits électriques par SMS**, multi-kits,
**fonctionnant sans Internet** (tout passe par le réseau GSM).

- **Package / `applicationId`** : `com.enmkit.app`
- **Version** : 1.0.0+1 · **SDK Dart** : ^3.7.0
- **Plateforme cible principale** : Android (iOS/desktop présents mais non prioritaires).

---

## 1. Vue d'ensemble

Chaque **kit** est un boîtier muni d'une carte SIM, relié à plusieurs **lignes**
(circuits électriques). L'application envoie des **SMS de commande** au numéro du kit
pour allumer/couper une ligne ou relever la consommation, et **écoute les SMS de
réponse** (écho) pour synchroniser l'état — y compris **application fermée**.

```
┌────────────┐   SMS commande (rNon/rNoff, cons, n1:/n2:/en:/ip:)   ┌──────────┐
│ App EnMKit │ ────────────────────────────────────────────────▶  │   Kit    │
│ (Android)  │ ◀──────────────────────────────────────────────── │ (SIM)    │
└────────────┘   SMS écho / relevé (rNon, kWh, n1:/n2:/…)          └──────────┘
      ▲
      │ plusieurs téléphones autorisés partagent l'état d'un même kit
```

---

## 2. Architecture (Clean / MVVM + Riverpod)

Découpage en couches, source unique d'injection dans `lib/providers.dart`.

```
lib/
├── main.dart                      # bootstrap + ProviderScope
├── providers.dart                 # tous les providers Riverpod (DI)
├── models/                        # POJO + (de)sérialisation Map<->SQLite
│   ├── kit_model.dart, relay_model.dart, consumption_model.dart
│   ├── allowed_number_model.dart, settings_model.dart
├── repositories/                  # accès données (SQLite via DBService)
│   ├── kit_repository.dart, relay_repository.dart, consumption_repository.dart
│   ├── allowed_number_repository.dart, settings_repository.dart, access_repository.dart
├── viewmodels/                    # ChangeNotifier (logique d'écran)
│   ├── kitViewModel.dart, relayViewmodel.dart, consumption_viewmodel.dart
│   ├── allowedNumberViewmodel.dart, smsViewmodel.dart, settings_viewmodel.dart
│   ├── access_viewmodel.dart, onboarding_vm.dart
├── core/
│   ├── db_service.dart            # ouverture DB + onCreate/onUpgrade
│   ├── sms_service_hybrid.dart    # construction & envoi des commandes SMS
│   ├── sms_inbox_processor.dart   # traitement des SMS entrants (écho/relevé)
│   ├── background_sms_bridge.dart # pont MethodChannel vers le natif
│   ├── sms_parser.dart, phone_formatter.dart
│   ├── qr_service.dart, qr_generate_database_service.dart
│   ├── i18n/strings.dart          # i18n maison (catalogue clé->valeur)
│   └── constants/defaults.dart, constants/onboarding_constants.dart
└── ui/
    ├── theme/app_theme.dart       # design system (couleurs, typo, ombres, durées)
    ├── widgets/common/            # SoftCard, IconPill, StatusBadge, premium.dart…
    └── screens/                   # onboarding, kits, kit_detail (relays/conso/config), settings, access…
```

### 2.1 Patron MVVM

- **Model** : objet pur + `toMap()` / `fromMap()`.
- **Repository** : seul à parler à `DBService` (SQLite). Pas de logique d'UI.
- **ViewModel** (`ChangeNotifier`) : état d'écran, appelle repositories & services,
  notifie l'UI via `notifyListeners()`.
- **View** : `ConsumerWidget` / `ConsumerStatefulWidget` qui `ref.watch(...)`.

### 2.2 Providers clés (`lib/providers.dart`)

| Provider | Type | Rôle |
|---|---|---|
| `dbServiceProvider` | `Provider<DBService>` | Singleton SQLite |
| `kitRepositoryProvider`, `relayRepositoryProvider`, … | `Provider<…Repository>` | Accès données |
| `accessProvider` | `ChangeNotifierProvider<AccessViewModel>` | PIN / verrouillage |
| `settingsProvider` | `ChangeNotifierProvider<SettingsViewModel>` | Thème, langue, accent, `securityCodeEnabled` |
| `tProvider` | `Provider<AppStrings>` | i18n : `t.t('clé')` / `t.tf('clé', [args])` |
| `kitProvider` | `ChangeNotifierProvider<KitViewModel>` | Liste des kits |
| `kitSmsServiceProvider` | `Provider.family<SmsServiceHybrid, String?>` | Service SMS **par kit** |
| (familles par `kitNumber`) | `Provider.family<…, String?>` | Données isolées par kit |

> **Isolation par kit.** Les services/VM liés à un kit sont des `*.family<_, String?>`
> indexés par `kitNumber` : chaque kit a son flux SMS, ses lignes et sa conso, sans
> mélange entre logements.

### 2.3 Flow d'accès — le code de sécurité, **priorité abaissée**

Le point d'entrée `RootPage` (`ui/screens/wrapper/wrapper.dart`) décide de l'écran via
`_screenFor(status, settingsVM)`. **L'ordre des décisions est déterminant :**

```
Démarrage (RootPage._screenFor)
│
├─ 1. onboarding non vu ?                          ──oui──▶ OnboardingScreen
│
├─ 2. !securityCodeEnabled && !securityPromptSeen ?──oui──▶ AccessScreen(firstRunSetup:true)
│        (1re connexion : on PROPOSE un code)                 = page code SKIPPABLE
│       non                                                   (bouton « Passer pour l'instant »)
│
├─ 3. securityCodeEnabled == false ?              ──oui──▶ MainShell (HOME)   ◀─ COURT-CIRCUIT
│        (drapeau app_settings)                                                l'AccessScreen
│       non                                                                    n'est pas atteint
│
└─ 4. switch(AccessStatus)
        unknown    ▶ Splash (BrandLoadingScreen)
        needsSetup ▶ AccessScreen (créer le code)
        locked     ▶ AccessScreen (saisir le code)
        unlocked   ▶ MainShell (HOME)
```

> 🔑 **Changement de priorité.** Le code de sécurité est passé de *gardien obligatoire*
> à *filtre conditionnel* :
> - **Étape 2** : au tout premier lancement, on **propose** un code via
>   `AccessScreen(firstRunSetup: true)`, qui affiche un bouton **« Passer pour
>   l'instant »** (`_skip → settings.completeSecurityPrompt(enabled: false)`). L'étape
>   **ne bloque jamais**.
> - **Étape 3** : le test `!securityCodeEnabled` s'exécute **avant** le
>   `switch(AccessStatus)` (étape 4) : quand la sécurité est désactivée, l'accès à la
>   home est **direct**.
>
> Le verrouillage au passage en arrière-plan (`AppLifecycleState.paused →
> accessProvider.lock()`) reste sans effet quand la sécurité est désactivée : l'étape 3
> court-circuite à la reprise.

États du PIN (`AccessStatus`, `viewmodels/access_viewmodel.dart`) :
`unknown` (chargement) → `needsSetup` (aucun code) / `locked` (code existant non saisi)
→ `unlocked`. Activation/désactivation depuis les Réglages :
`setupSecurity()` (pose le code) / `disableSecurity(pin)` (vérifie puis `clearPin()`),
le tout piloté par `settings.setSecurityCodeEnabled(bool)`.

#### Scénario « tout premier lancement » (install neuve)

Valeurs par défaut (`settings_model.dart`) : `onboardingSeen = false`,
`securityCodeEnabled = false` **et** `securityPromptSeen = false`.

```
1. Lancement              ▶ Splash (BrandLoadingScreen)            [settings en chargement]
2. onboardingSeen=false   ▶ OnboardingScreen (3 slides ; « Passer » / « Commencer »)
3. onDone → setOnboardingSeen()   →   onboardingSeen=true (persisté)
4. !securityCodeEnabled && !securityPromptSeen
                          ▶ AccessScreen(firstRunSetup:true)  = PAGE CODE SKIPPABLE
                            ├─ « Passer pour l'instant » → completeSecurityPrompt(enabled:false)
                            └─ code créé + confirmé        → completeSecurityPrompt(enabled:true)
5. securityPromptSeen=true (les deux chemins)  ▶ MainShell (HOME)
6. Aux ouvertures suivantes : la page n'est PLUS proposée.
```

> **Le changement de comportement le plus visible est ici.**
>
> | | Ancien flow | Flow actuel |
> |---|---|---|
> | Après l'onboarding | onboarding → **création PIN obligatoire** → home | onboarding → **page code SKIPPABLE** → home |
> | Bouton « Passer » sur la page de code | absent (bloquant) | **présent** (`firstRunSetup`) |
> | `AccessStatus = needsSetup` (aucun PIN) | menait à un `AccessScreen` bloquant | proposé **une fois**, puis court-circuité |
> | Le code | imposé d'emblée | **choix** (1re connexion ou Réglages → Sécurité) |
>
> Le drapeau `securityPromptSeen` (table `app_settings`) garantit que la proposition
> n'apparaît **qu'une seule fois**. `OnboardingScreen.onDone` n'appelle **que**
> `setOnboardingSeen()` ; la création éventuelle du code se fait sur la page skippable,
> jamais de façon imposée.

---

## 3. Base de données (SQLite via `sqflite`)

Fichier : `kit_control.db`. **Version courante : 9.** Ouverture dans
`core/db_service.dart` (`onCreate` + `onUpgrade`).

### 3.1 Schéma des tables

| Table | Colonnes principales |
|---|---|
| `users` | `id`, `phoneNumber`, `password`, `isAdmin`, `hasConnected` |
| `kits` | `kitNumber` (PK), `name`, `initialConsumption`, `pulseCount` |
| `relays` | `id` (PK), `name`, `isActive`, `amperage`, `ackReceived` (def. 0), `kitNumber` |
| `consumptions` | `id`, `kWh`, `timestamp`, `kitNumber` |
| `allowed_numbers` | `id`, `phoneNumber`, `kitNumber` |
| `configurations` | `id`, `language`, `themeMode`, `notificationsEnabled` |
| `app_security` | `id=1`, `pinHash`, `salt` |
| `app_settings` | `id=1`, `themeMode`, `locale`, `accent`, `onboardingSeen`, `securityCodeEnabled`, `securityPromptSeen` |

> La table `relays` conserve son nom technique ; côté métier/UI on parle de **lignes**.

### 3.2 Historique des migrations (`onUpgrade`)

| → version | Changement |
|---|---|
| 2 | `relays.ackReceived` (accusé de réception) |
| 3 | Multi-kits : `kits.name`, `kitNumber` ajouté à `relays`/`consumptions`/`allowed_numbers` |
| 4 | Table `app_security` (PIN remplace l'écran de connexion) |
| 5 | Table `app_settings` (thème, langue, accent) |
| 6 | `app_settings.onboardingSeen` |
| 7 | `app_settings.securityCodeEnabled` + activation auto si un PIN existait déjà |
| **8** | **Renommage `Relais N` → `Ligne N`** des noms par défaut déjà stockés |
| **9** | `app_settings.securityPromptSeen` (proposition de code skippable) + marquée *vue* pour les installs existantes |

Migration v8 (extrait) :

```sql
UPDATE relays SET name = 'Ligne ' || substr(name, 8)
WHERE name LIKE 'Relais %';
```

> `substr(name, 8)` saute le préfixe `"Relais "` (7 caractères) et conserve le
> suffixe (numéro). Les noms personnalisés ne commençant pas par `Relais ` sont
> intacts.

### 3.3 Sécurité du PIN

`access_repository.dart` stocke `pinHash` + `salt` (paquet `crypto`). Le code clair
n'est jamais persistant. `clearPin()` efface l'enregistrement quand on désactive la
sécurité. Le **basculement optionnel** est porté par `app_settings.securityCodeEnabled`.

---

## 4. Protocole SMS (matériel) — **ne pas modifier les mots-clés**

Construction et envoi dans `core/sms_service_hybrid.dart`.

| Action | Message envoyé au kit | Réponse attendue (écho/relevé) |
|---|---|---|
| Allumer la ligne *N* | `r<N>on` (ex. `r2on`) | écho `r2on` |
| Couper la ligne *N* | `r<N>off` (ex. `r2off`) | écho `r2off` |
| Relever la consommation / **ping** | `cons` | relevé (kWh) |
| Numéro autorisé 1 | `n1:<numéro>` | écho `n1:…` |
| Numéro autorisé 2 | `n2:<numéro>` | écho `n2:…` |
| Consommation initiale | `en:<kWh>` | écho `en:…` |
| Impulsions compteur | `ip:<count>` | écho `ip:…` |
| Fin de configuration | `Fin_config` | — |

La configuration groupée concatène plusieurs champs séparés par `;`
(ex. `n1:…;n2:…;en:…;ip:…`). Les numéros sont normalisés au format `+237`
(`formatPhoneNumber`).

**Réponses entrantes reconnues** (`core/sms_inbox_processor.dart`) :

| Réponse du kit | Motif | Traitement |
|---|---|---|
| Écho de ligne | `r(\d+)\s*(on\|off)` (toutes occurrences) | `applyKitAck` → `isActive` + `ackReceived` |
| Relevé conso | `(\d+(?:[.,]\d+)?)\s*kwh` | ajout `consumptions` (dédup ≤ 3 min) |
| Écho config | `n1:` / `n2:` / `en:` / `ip:` | `parseAckMessage` |

### 4.1 Synchronisation d'état (écho)

- Le SMS entrant est parsé pour toutes les occurrences de `r(\d+)\s*(on|off)`.
- Pour chaque ligne *N*, on pose `isActive` selon `on/off` **et** `ackReceived = 1`
  via `RelayRepository.applyKitAck(id, isActive, kitNumber)`.
- Conséquence : **tout téléphone autorisé** reflète l'état réel renvoyé par le kit.

### 4.2 Joignabilité (`smsViewmodel.dart`)

```text
enum KitReachability { unknown, checking, reachable, unreachable }
armReachabilityCheck({uiTimeout = 45s})  // « Tester » envoie un ping `cons`
// À la réception d'un SMS du kit pendant 'checking' → 'reachable' (timer annulé).
```

### 4.3 Actions groupées

`RelayViewModel.setAllRelays(bool on)` : n'émet une commande que pour les lignes
**réellement modifiées**, avec un délai de **400 ms** entre deux envois (évite la
rafale SMS).

### 4.4 Rôles (tels que conçus)

| Rôle | Porté par | Périmètre / qui l'applique | Statut |
|---|---|---|---|
| **Code d'accès (PIN)** | `app_security` + `app_settings.securityCodeEnabled` | Protège l'**ouverture locale** de l'app (voir §2.3) | **Optionnel** (désactivable) |
| **Numéro du kit** (`trustedSender`) | `kits.kitNumber` | **Seule source SMS acceptée** : filtré côté **app** (`SmsListenerViewModel.isFromTrusted`) **et côté natif** (`SmsReceiver` → `SmsStore.isKnownKit(sender)`) avant empilage | Identité du kit |
| **Numéros autorisés** (`n1` / `n2`) | `allowed_numbers` + envoyés au kit (`n1:`/`n2:`) | Qui peut **commander le kit** — contrôle appliqué **par le KIT**, pas par l'app | Jusqu'à 2 |
| **Admin (héritage)** | table `users` (`666666666` / `1234`, cf. `defaults.dart`) | Vestige de l'ancien login par identifiants | Legacy |

> **Appariement des numéros** : comparaison sur les **8 derniers chiffres** (tolère les
> indicatifs), implémentée à l'identique dans `smsViewmodel._numbersMatch` et
> `sms_inbox_processor._tail`.
>
> **Multi-téléphones.** Tout téléphone ayant importé un kit (par QR) possède le même
> `kitNumber` comme `trustedSender` : il reçoit donc les échos et **synchronise l'état
> des lignes**, application fermée comprise.

---

## 5. Réception SMS en arrière-plan (natif Android)

Permissions (`AndroidManifest.xml`) : `SEND_SMS`, `RECEIVE_SMS`, `READ_SMS`,
`READ_PHONE_STATE`, `POST_NOTIFICATIONS`, `CAMERA`, `INTERNET`.

| Fichier Kotlin (`com.example.enmkit`) | Rôle |
|---|---|
| `SmsReceiver.kt` | `BroadcastReceiver` déclaré dans le manifeste : capte les SMS entrants même app fermée |
| `SmsStore.kt` | File d'attente persistante des SMS reçus en tâche de fond |
| `SmsEventBridge.kt` | Émission d'événements vers Flutter |
| `MainActivity.kt` | Enregistre les `MethodChannel`/`EventChannel` |

Côté Dart : `BackgroundSmsBridge` (pont MethodChannel) → `SmsInboxProcessor`
**draine** les SMS stockés et applique les écho via les repositories. Le drainage est
déclenché au démarrage et à la reprise (`wrapper.dart`).

---

## 6. Internationalisation

i18n **maison** (pas de `.arb`) dans `core/i18n/strings.dart` :
- `AppStrings` expose un `_catalog` `Map<clé, valeur>` par langue (fr / en).
- Usage : `final t = ref.watch(tProvider); t.t('relays.control')`,
  ou `t.tf('clé', [args])` pour l'interpolation.
- La langue suit `settingsProvider.settings.locale`.

---

## 7. Design system (`ui/theme/app_theme.dart`)

- **Couleurs** : `indigo` (primaire), `emerald` (succès), `coral` (danger), `amber`,
  `cyan`, `pink` ; encre `ink` / `inkSoft`.
- **Métriques** : `radius = 20` (cartes), `radiusControl = 14` (contrôles), `gap = 16`.
- **Ombres** : `elevedShadow(tint, strength)` (alias `softShadow`).
- **Durées** : `fast 200ms`, `normal 400ms`, `slow 650ms`.
- **Typo** : Google Fonts **Chakra Petch**.
- **Briques UI** : `SoftCard`, `IconPill`, `StatusBadge`, `GradientHeroCard`,
  `StatTile`, `AnimatedCount`, `GlassIconButton`, `showAppSheet` / `SheetField`.
- **Animations** : `flutter_animate` (entrées en cascade fadeIn/slideX).

---

## 8. QR Code (partage de configuration)

- `qr_service.dart` / `qr_generate_database_service.dart` sérialisent la configuration
  d'un kit en QR (paquet `pretty_qr_code`), partage image via `share_plus`.
- Import par scan caméra (`mobile_scanner`) → recrée le kit et sa config sur un autre
  téléphone, qui peut alors piloter le même logement.

---

## 9. Dépendances notables (`pubspec.yaml`)

`flutter_riverpod`, `provider`, `sqflite`, `sms_sender_background`,
`readsms` (paquet local `local_packages/readsms`), `fl_chart`, `pretty_qr_code`,
`mobile_scanner`, `image_picker`, `permission_handler`, `url_launcher`, `crypto`,
`google_fonts`, `flutter_animate`, `share_plus`, `curved_navigation_bar`, `screenshot`.

---

*EnMKit — Documentation technique. Voir aussi `docs/GUIDE_UTILISATION.md`,
`docs/NOTES_DE_VERSION.md` et `README.md`.*
