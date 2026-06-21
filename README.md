# EnMKit — Application mobile

**Pilotez vos kits électriques par SMS, sans Internet.**

EnMKit est une application **Flutter** (Android prioritaire) qui commande des kits
électriques à distance via **SMS** : allumage/coupure des **lignes** (circuits),
relevé de consommation, configuration du boîtier, et partage de configuration par
**QR Code**. Multi-kits : un seul téléphone pilote tout un parc de logements.

- `applicationId` : `com.enmkit.app` · Version : **1.0.0+1**
- Flutter **stable 3.41.x** · Dart **^3.7.0**

📚 Voir aussi :
[Guide d'utilisation](docs/GUIDE_UTILISATION.md) ·
[Documentation technique](docs/DOC_TECHNIQUE.md) ·
[Notes de version](docs/NOTES_DE_VERSION.md)

---

## 1. Prérequis

- **Flutter SDK** stable (≥ 3.41) et **Dart** ≥ 3.7 — `flutter doctor` au vert.
- **Android SDK** + `platform-tools` (`adb`) pour déployer sur appareil.
- Un **appareil Android physique** (l'envoi/réception de SMS réels nécessite une SIM ;
  l'émulateur ne reçoit pas de SMS du kit).

---

## 2. Installation du projet

```bash
cd App_Mobile_EnMKit
flutter pub get          # inclut le paquet local local_packages/readsms
```

Lancer en développement sur un appareil branché :

```bash
flutter devices          # vérifier que l'appareil est listé
flutter run              # build debug + hot reload
```

---

## 3. Permissions Android

Déclarées dans `android/app/src/main/AndroidManifest.xml` :
`SEND_SMS`, `RECEIVE_SMS`, `READ_SMS`, `READ_PHONE_STATE`, `POST_NOTIFICATIONS`,
`CAMERA`, `INTERNET`.

> L'app **écoute les SMS entrants même fermée** via un `BroadcastReceiver` natif
> (`SmsReceiver`). Sur certains constructeurs (Transsion/Tecno/Infinix…), pensez à
> autoriser l'**autostart** et à exclure l'app de l'optimisation batterie.

---

## 4. Build & signature release

La signature release est chargée depuis `android/key.properties` (voir
`android/app/build.gradle.kts`). Si ce fichier est absent, le build **retombe sur la
signature debug** (pratique pour un clone sans keystore).

### 4.1 Fichier `android/key.properties`

```properties
storePassword=********
keyPassword=********
keyAlias=********
storeFile=enmkit-release.jks
```

Le keystore attendu est `android/app/enmkit-release.jks`.

> 🔐 **Sécurité.** Le keystore et `key.properties` **ne doivent jamais être versionnés**.
> Ils sont désormais listés dans `.gitignore`. Conservez-en une **sauvegarde sûre** :
> sans ce keystore, vous ne pourrez plus publier de mise à jour compatible avec les
> installations existantes.

### 4.2 Construire l'APK

```bash
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk (~71 Mo)
# ou un App Bundle pour le Play Store :
flutter build appbundle --release
```

---

## 5. Déploiement sur appareil

```bash
# adb doit être sur le PATH (ex. ~/Android/Sdk/platform-tools)
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`-r` réinstalle **en conservant les données** (la base SQLite et donc les kits/lignes
sont préservés ; les migrations de schéma s'exécutent au premier lancement).

> ⚠️ **Conflit de signature.** On ne peut pas écraser un APK **release** par un APK
> **debug** (signatures différentes : `INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Pour
> mettre à jour un appareil déjà équipé, rebâtissez en **release** avec le même
> keystore. Désinstaller puis réinstaller efface les données.

---

## 6. Structure du dépôt

```
App_Mobile_EnMKit/
├── lib/                 # code Dart (voir docs/DOC_TECHNIQUE.md §2)
├── android/             # natif Android + signature (key.properties, *.jks)
│   └── app/src/main/kotlin/com/example/enmkit/  # SmsReceiver, SmsStore, …
├── local_packages/
│   └── readsms/         # paquet local de lecture des SMS
├── docs/                # guide utilisateur, doc technique, notes de version, captures
├── test/                # tests
└── pubspec.yaml
```

---

## 7. Dépannage rapide

| Symptôme | Piste |
|---|---|
| `adb: command not found` | Ajouter `platform-tools` au PATH |
| Appareil absent de `adb devices` | `adb kill-server && adb start-server`, rebrancher le câble |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Rebâtir en **release** (même keystore) — voir §5 |
| L'app ne reçoit pas les SMS du kit fermée | Autoriser autostart + exclure de l'optimisation batterie |
| Le kit ne répond pas | Tester la joignabilité (bouton **Tester**, ping `cons`) ; vérifier crédit SMS de la SIM du kit |

---

*EnMKit — Application mobile. Documentation dans `docs/`.*
