# Notes de version : EnMKit

> Application Flutter de pilotage de kits électriques par SMS (multi-kits, sans Internet).
> `applicationId` : `com.enmkit.app` · Version applicative : **1.0.1+4**.

---

## Version 1.0.1 : alignement sur les correctifs de l'app EnMKit Banc

Date du document : 30/10/2026. Build `1.0.1+4` (versionCode 4).

Cette version reprend les corrections d'ergonomie et de textes faites sur l'app
sœur EnMKit Banc. Les fonctions propres au banc (analyse IA, trames horaires,
module Apprendre, assistant et serveur EnMKit) ne font **pas** partie de l'app client.
Aucun mot-clé du protocole SMS du kit n'a changé.

### ✨ Nouveautés

- **Onglet Lignes.** Carte **« Connexion du kit »** avec un bouton **Tester**
  (le kit doit répondre dans les 45 secondes) et **actions rapides**
  **« Tout allumer » / « Tout éteindre »** (seules les lignes qui changent d'état
  reçoivent un SMS). Tant que le kit n'a pas reçu sa configuration (onglet Config),
  un bandeau l'indique et les boutons ON / OFF restent désactivés.
- **Barre de navigation flottante en icônes** (Accueil, Aide, Réglages) : une bulle
  glisse sous l'onglet actif ; le nom de l'onglet apparaît en appui long et reste
  lu par les lecteurs d'écran. La pastille rouge de l'onglet Aide signale toujours
  une réponse du support.
- **FAQ intégrée réécrite** d'après l'app actuelle, en français et en anglais
  (vouvoiement) : 4 catégories (Accès et sécurité, Kit et lignes, QR Code et
  partage, Dépannage), 25 questions.

### 🐞 Corrections

- **Code d'accès : exactement 4 chiffres** à la création, au changement et à la
  récupération (le clavier de déverrouillage n'en saisit que 4 : un code plus long
  bloquait l'accès). Messages et libellés mis à jour.
- Accueil : la pastille d'état d'un kit n'est **verte** que si le kit a bien reçu sa
  configuration, orange sinon.
- Réglages > À propos : la version affichée est lue dans le paquet installé
  (elle n'est plus figée à « 1.0.0 »).
- Textes : « Passer pour l'instant », objets de demande au support et titre
  « Aide & assistance » traduits en anglais ; le message de consommation vide cite
  le vrai bouton « Vérifier votre consommation électrique » ; plus de mention
  d'ampérage à l'ajout ou à la modification d'une ligne ; le code d'accès est
  présenté comme optionnel dans la présentation ; plus aucun tiret cadratin ni
  demi-cadratin dans les textes.

### ⚠️ Notes de migration

- Mise à jour par-dessus la version 1.0.0 **sans perte de données** (kits, lignes,
  accusés, consommation, réglages), avec le même APK *release* signé.
- **Le code d'accès est réinitialisé à la mise à jour** : le numéro de build change
  (3 → 4), ce que détecte `lib/core/security_reset.dart`. Le code, ses questions de
  récupération et le déverrouillage par empreinte sont effacés et l'application
  propose à nouveau d'en créer un (« Passer pour l'instant » reste possible). C'est
  le comportement voulu ; prévenez les utilisateurs. Un code créé avant cette
  version et qui comptait plus de 4 chiffres disparaît ainsi de lui-même.

---

## Version 1.0.0 — Lot « Lignes, sécurité optionnelle & temps réel »

Date du document : 02/06/2026.

Cette livraison fait évoluer le vocabulaire, la sécurité, l'édition des circuits et
l'écoute SMS en arrière-plan. Aucun mot-clé du protocole SMS matériel n'a changé.

### ✨ Nouveautés

- **Code de sécurité optionnel.**
  Le code d'accès (PIN) n'est plus imposé : c'est désormais un **choix** activable
  dans **Réglages → Sécurité**. À la première utilisation sans code activé,
  l'application ouvre directement le tableau de bord.
  - Les installations déjà protégées par un PIN le **restent** (migration douce).
  - Activer le code propose la création d'un PIN ; le désactiver demande le PIN
    actuel puis efface le code stocké.

- **Proposition de code skippable au 1er lancement.**
  Juste après l'onboarding, l'application **propose** de créer un code, mais la page
  comporte un bouton **« Passer pour l'instant »** : l'étape ne **bloque jamais**
  l'accès à la home. La proposition n'apparaît **qu'une seule fois** (drapeau
  `securityPromptSeen`). Créer un code l'active ; passer mène droit au tableau de bord.

- **« Relais » renommé « Ligne » partout.**
  Toute l'interface parle désormais de **lignes** (onglet, libellés, formulaires).
  Une **migration de base de données** renomme aussi les noms déjà enregistrés
  (`Relais 2` → `Ligne 2`) ; les noms personnalisés (ex. *Climatiseur*) sont préservés.

- **Synchronisation d'état en temps réel + écoute en arrière-plan.**
  Quand le kit renvoie l'écho de la commande (`r2on` / `r2off`), **toutes les
  applications autorisées** mettent à jour l'état ON/OFF de la ligne concernée.
  L'application **écoute les SMS entrants même fermée** (récepteur natif Android).

- **Choix du nombre de lignes à la création du kit.**
  À la création, on choisit **4**, **7**, ou un nombre **personnalisé** (1 à 7).
  Les lignes sont alors générées automatiquement (`Ligne 1`, `Ligne 2`, …).

- **Édition d'une ligne par double-tap.**
  Un **double-tap** sur une ligne passe la carte en édition *inline* (champ texte
  + boutons circulaires **✓ vert** valider / **✕ rouge** supprimer), épurés et soft.
  L'information d'**ampérage a été retirée** de l'ajout/édition d'une ligne.

- **Joignabilité du kit & actions groupées.**
  Une carte **« Connexion du kit »** propose un bouton **Tester** (ping `cons`) et
  une **bannière de statut** (Inconnu / Vérification / Joignable / Injoignable).
  Deux **actions rapides** : **Tout allumer** / **Tout éteindre**.

- **Design progressif et intégré.**
  Animations d'entrée en cascade sur l'onglet Lignes, cohérence du design system
  (cartes soft, ombres teintées, typographie Chakra Petch).

### 🛠️ Détails techniques

- **Base de données** : version **7 → 9**.
  - v8 — migration `UPDATE relays SET name = 'Ligne ' || substr(name, 8)
    WHERE name LIKE 'Relais %'` (renommage des lignes).
  - v9 — colonne `app_settings.securityPromptSeen` (proposition de code skippable),
    marquée *vue* (`= 1`) pour les installs existantes.
  - La version 7 avait ajouté la colonne `app_settings.securityCodeEnabled`.
- **Flow d'accès** (`wrapper.dart`) : nouvelle branche `firstRunSetup` — au 1er
  lancement, `AccessScreen(firstRunSetup: true)` avec bouton « Passer pour l'instant »
  (`settings.completeSecurityPrompt(enabled: …)`).
- **Repository lignes** : `seedLines(kitNumber, count)` (borne 1..7) remplace
  l'ancien `seedDefaultRelays` ; nouvelle méthode `applyKitAck(...)` qui pose
  `isActive` + `ackReceived` à la réception de l'écho.
- **ViewModel SMS** : `enum KitReachability { unknown, checking, reachable, unreachable }`
  + `armReachabilityCheck()` ; `setAllRelays(bool on)` n'émet que pour les lignes
  réellement modifiées (délai de 400 ms entre deux envois).
- **Natif Android** : `SmsReceiver`, `SmsStore`, `SmsEventBridge`, `MainActivity`
  (package `com.example.enmkit`) ; `BackgroundSmsBridge` côté Dart, drainé via
  `SmsInboxProcessor`.

### ⚠️ Notes de migration

- La mise à jour s'installe **par-dessus** l'app existante **sans perte de données**
  (APK release signé avec `enmkit-release.jks`). La migration BD s'exécute au
  premier lancement.
- Un APK *debug* ne peut pas écraser un APK *release* (signatures différentes) :
  toujours rebâtir en **release** pour mettre à jour un appareil déjà équipé.

---

## Format des prochaines entrées

```
## Version X.Y.Z — Titre du lot
Date.
### ✨ Nouveautés
### 🛠️ Détails techniques
### 🐞 Corrections
### ⚠️ Notes de migration
```

---

*EnMKit — Notes de version.*
