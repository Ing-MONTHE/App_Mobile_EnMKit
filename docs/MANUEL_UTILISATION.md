# Manuel d'utilisation · EnMKit Banc

**Application mobile du banc de formation « Smart Home Learning Lab »**

Éditeur : 2ME Technologies SARL · contact@2metechsarl.org · https://www.2metechsarl.org
Application : EnMKit Banc (Android), version 1.1.0
Public : formateurs et apprenants des établissements de formation.

---

## Sommaire

1. Présentation et installation
2. Premier lancement
3. Ajouter et piloter un kit
4. Analyse IA
5. Module Apprendre
6. Assistant énergie et tuteur de TP
7. Aide et support
8. Réglages
9. Dépannage

---

## 1. Présentation et installation

### 1.1 À quoi sert l'application

EnMKit Banc pilote les kits électriques EnMKit **par SMS**. Aucune connexion Internet n'est nécessaire pour l'essentiel des fonctions.

Avec l'application, vous pouvez :

- allumer et éteindre les **lignes** d'un kit (ON / OFF) ;
- demander la **consommation** relevée par le compteur ;
- recevoir les **trames horaires** de consommation envoyées par le kit ;
- consulter une **Analyse IA** calculée sur le téléphone (score, note, prévisions en kWh et en FCFA, anomalies, recommandations) ;
- suivre les **7 travaux pratiques** (TP1 à TP7) du banc, avec quiz, éco-gestes et glossaire ;
- poser des questions à l'**Assistant énergie** (en ligne si un serveur est configuré, hors-ligne sinon) ;
- contacter le **support** EnMKit par SMS ou WhatsApp.

Sur le banc, les lignes sont câblées ainsi : **L1 et L2 = ampoules**, **L3 et L4 = prises**, toutes en parallèle sous 220 V.

### 1.2 Installer l'APK

L'application est distribuée sous forme de fichier APK (Android uniquement).

1. Sur le téléphone, ouvrez https://www.2metechsarl.org et téléchargez l'APK **EnMKit Banc**.
2. Ouvrez le fichier téléchargé.
3. Si Android le demande, autorisez l'installation depuis cette source (navigateur ou gestionnaire de fichiers).
4. Appuyez sur **Installer**, puis **Ouvrir**.

> EnMKit Banc est une application distincte de l'application client EnMKit. Les deux peuvent être installées sur le même téléphone.

### 1.3 Permissions demandées

Au démarrage, l'application demande les autorisations suivantes. Acceptez-les : sans elles, le pilotage ne fonctionne pas.

| Permission | Pourquoi |
|---|---|
| SMS (envoi, réception, lecture) | Envoyer les commandes au kit et lire ses réponses, y compris application fermée. |
| Notifications | Vous prévenir à l'arrivée d'une réponse (Android 13 et plus). |
| Appareil photo | Scanner le QR Code d'un kit. |
| Empreinte digitale | Déverrouillage par empreinte (facultatif). |
| Internet | Uniquement pour l'Assistant énergie en ligne (facultatif). |

Le téléphone doit avoir une **carte SIM active avec du crédit SMS**. Le kit doit lui aussi avoir une SIM avec du réseau et du crédit.

---

## 2. Premier lancement

### 2.1 Présentation (onboarding)

Trois écrans présentent l'application :

1. **Pilotez vos kits à distance**
2. **Suivez votre consommation**
3. **Sécurisé et multi-kits**

Appuyez sur **Suivant** pour avancer, **Commencer** sur le dernier écran, ou **Passer** pour aller directement à la suite. Cette présentation n'apparaît qu'une fois.

### 2.2 Code de sécurité (optionnel)

Juste après la présentation, l'application propose de créer un code d'accès. Ce code est **facultatif**.

- Pour ne pas en créer : appuyez sur **Passer pour l'instant**. Vous arrivez directement sur l'accueil.
- Pour en créer un :
  1. Saisissez un code d'**au moins 4 chiffres** (**Créez votre code**).
  2. Saisissez-le à nouveau (**Confirmez le code**).
  3. Choisissez deux **Questions de récupération** différentes et répondez-y. Elles servent en cas d'oubli (la casse et les espaces sont ignorés).
  4. Si le téléphone a une empreinte enregistrée, l'application propose **Activer l'empreinte** ou **Plus tard**.

Cette proposition n'apparaît qu'une seule fois. Vous pourrez activer ou désactiver le code plus tard dans **Réglages > Sécurité** (voir section 8).

Code oublié : sur l'écran de saisie du code, appuyez sur **Code oublié ?**, répondez à vos deux questions, puis définissez un nouveau code avec **Réinitialiser le code**.

### 2.3 Se déplacer dans l'application

La barre de navigation du bas est **flottante** et n'affiche que des **icônes**. Elle compte 4 onglets :

| Position | Onglet | Contenu |
|---|---|---|
| 1 | **Accueil** | Vos kits (« Mes kits »). |
| 2 | **Apprendre** | Les TP, éco-gestes, glossaire et l'Assistant énergie. |
| 3 | **Aide** | Demande d'assistance et conversation avec le support. |
| 4 | **Réglages** | Apparence, langue, sécurité, serveur, FAQ. |

- **Appui long** sur une icône : affiche le nom de l'onglet.
- **Point rouge sur l'icône Aide** : le support vous a répondu et vous n'avez pas encore lu la réponse. Il disparaît dès que vous ouvrez l'onglet Aide.

---

## 3. Ajouter et piloter un kit

### 3.1 Ajouter un kit

1. Dans l'onglet **Accueil**, appuyez sur le bouton **+** (en bas à droite).
2. Dans la fenêtre **Nouveau kit** :
   - **Nom du kit** : par exemple « Banc 1 » ;
   - **Numéro du kit** : le numéro de la carte SIM du kit (obligatoire) ;
   - **Nombre de lignes** : **4**, **7** ou **Personnalisé** (de 1 à 7 avec les boutons moins et plus).
3. Appuyez sur **Ajouter le kit**.

Les lignes sont créées automatiquement (« Ligne 1 », « Ligne 2 », etc.). Pour le banc du Learning Lab, choisissez **4**.

**Importer un kit par QR Code** : dans l'en-tête de l'accueil, appuyez sur l'icône de scanner, puis placez le QR Code du kit dans le cadre (**Scanner un kit**). Le message « Kit « … » importé » confirme l'import.

**Supprimer un kit** : faites glisser sa carte vers la gauche ou la droite, puis confirmez. Toutes ses données (lignes, accusés, consommation, relevés horaires) sont supprimées. Cette action est irréversible.

### 3.2 L'écran d'un kit

Touchez la carte d'un kit pour l'ouvrir. L'écran comporte 4 onglets :

| Onglet | Rôle |
|---|---|
| **Lignes** | Allumer et éteindre chaque ligne. |
| **Conso** | Demander et consulter la consommation. |
| **Analyse IA** | Analyse des trames horaires (section 4). |
| **Config** | Paramètres du kit, numéros autorisés, envoi de la configuration, QR Code. |

### 3.3 Configurer le kit (onglet Config)

À faire une fois, avant de piloter le kit.

1. Ouvrez l'onglet **Config**.
2. Vérifiez **Informations du kit** (Nom, Numéro du kit). Appuyez sur la carte pour modifier.
3. Renseignez **Compteur** :
   - **Impulsion par kWh** : la constante du compteur (nombre entier supérieur à 0, par exemple 1000) ;
   - **Consommation initiale** : l'index de départ du compteur, en kWh.
4. Renseignez les **Numéros autorisés** (**Numéro 1** et **Numéro 2**) : ce sont les téléphones qui pourront commander le kit. Double-appuyez sur un champ pour le modifier, puis validez avec le bouton vert (ou annulez avec le rouge).
5. Appuyez sur **Envoyer la configuration au kit**.
6. Vérifiez le récapitulatif **Vérifier la configuration**, puis appuyez sur **Envoyer au kit**.

Un volet d'état suit ensuite la configuration :

| État affiché | Signification | Action |
|---|---|---|
| **Configuration envoyée** (EN COURS) | Le kit n'a pas encore répondu. La réponse peut prendre plusieurs minutes et sera reconnue même si vous quittez l'application. | Patienter. |
| **Le retour du kit correspond** (OK) | Le kit a renvoyé exactement ce qui lui a été envoyé. | Appuyer sur **Valider et verrouiller**, relire, puis **OK**. |
| **Configuration verrouillée** (VERROUILLÉ) | La configuration est close. | Plus de modification possible. |

> Attention : la validation est **définitive**. Toute modification ultérieure devra passer par les administrateurs. Relisez bien les numéros et les paramètres du compteur avant de valider.

Sur l'accueil, une puce **À valider** sur la carte d'un kit indique qu'il ne reste que cette validation finale. Touchez-la pour l'effectuer.

**Partager un kit** : dans **Config**, appuyez sur **Générer le QR Code**, puis **Partager le QR Code**. Un autre téléphone pourra l'importer (section 3.1).

### 3.4 Piloter les lignes (onglet Lignes)

Chaque ligne a deux boutons : **ON** et **OFF**.

1. Appuyez sur **ON** pour allumer, **OFF** pour éteindre.
2. Le téléphone envoie un SMS au kit. Pendant l'attente, les deux boutons de la ligne sont bloqués (pas de double envoi).
3. Quand le kit confirme, l'état est mis à jour.

Les boutons ne montrent pas l'état « supposé » de la ligne : ce sont de simples commandes. L'état fiable est celui **confirmé par le kit**. Pour le consulter, appuyez sur l'icône **horloge** de la ligne : la fenêtre **Confirmation de la commande** liste les confirmations horodatées (par exemple « Ligne 1 est alimenté(e) », « Aujourd'hui 09:12 »).

**Renommer ou supprimer une ligne** : double-appuyez sur la carte de la ligne. Modifiez le nom, puis appuyez sur le bouton vert pour valider, ou sur le bouton rouge pour supprimer la ligne.

En haut de l'onglet :

- **Connexion du kit** : appuyez sur **Tester**. Le téléphone envoie une demande de consommation au kit. Le statut passe à « Vérification du kit… », puis à **Kit joignable** si le kit répond dans les 45 secondes, sinon à « Kit injoignable » (vérifiez alors la carte SIM du kit : réseau et crédit SMS).
- **Actions rapides** : **Tout allumer** ou **Tout éteindre**. Seules les lignes qui changent d'état reçoivent une commande, avec un court délai entre chaque SMS.

### 3.5 Consommation (onglet Conso)

1. Ouvrez l'onglet **Conso**.
2. Appuyez sur **Vérifier votre consommation électrique**.
3. Le message **Demande envoyée au kit…** puis **En attente de la réponse du kit…** s'affiche.
4. À réception : **Nouvelle mesure reçue**. La **Dernière mesure** est mise à jour.

Sous la dernière mesure, vous trouvez la courbe **Évolution** et la liste **Historique** des relevés.

Sans réponse dans le délai prévu : **Aucune réponse du kit. Vérifiez le réseau/numéro et réessayez.**

Ce relevé d'index (à la demande) est différent des **trames horaires**, que le kit envoie de lui-même et qui alimentent l'Analyse IA.

---

## 4. Analyse IA

### 4.1 D'où viennent les données

Le kit envoie sa consommation **heure par heure** par SMS, sous la forme :

```
JJ/MM/AA;HH;KWH
```

Exemple : `27/06/26;09;0.12` signifie 0,12 kWh consommés le 27/06/2026 entre 9 h et 10 h.

- Les trames sont reconnues **même application fermée**.
- Si la même heure arrive deux fois, seule la dernière valeur est conservée.
- L'analyse est **calculée sur le téléphone, sans Internet**, sur les 28 derniers jours.

### 4.2 État vide

Tant qu'aucune trame n'est reçue, l'onglet affiche **Pas encore de trames horaires**, avec un exemple de trame. C'est normal pour un kit neuf : l'analyse apparaît dès les premières trames. Tirez l'écran vers le bas pour actualiser.

### 4.3 Lire chaque bloc

| Bloc | Ce qu'il montre | Comment le lire |
|---|---|---|
| **Score d'efficacité** et **Note** | Score sur 100 et note de A à E. Date de la **Dernière trame**. | A : 85 et plus · B : 70 à 84 · C : 55 à 69 · D : 40 à 54 · E : moins de 40. La ligne **Pénalités** détaille les points retirés : veille (max 40), pointe (max 20), tendance (max 20), anomalies (max 20). |
| Mention « Peu de données » | Moins de 72 heures reçues. | L'analyse s'affinera après quelques jours de trames. |
| **Aujourd'hui (prévu)** | kWh prévus pour la journée et coût estimé. | Heures reçues + heures restantes estimées d'après le profil habituel. |
| **Ce mois (prévu)** | kWh prévus pour le mois et coût en FCFA. | Coût au barème progressif ENEO (voir ci-dessous). |
| **Moyenne / jour** | Consommation moyenne par jour. | Moyenne horaire reçue × 24. |
| **Veille (nuit)** | Puissance de veille (W) et part de la consommation. | Mesurée la nuit (0 h à 5 h). Une veille élevée = appareils qui consomment pour rien. |
| **Heure de pointe** | Heure la plus chargée et part de l'énergie consommée entre 18 h et 23 h. | Le soir est la pointe du réseau ENEO. |
| **Tendance 7 j** | Variation des 7 derniers jours par rapport aux 7 précédents. | « - » si les données sont insuffisantes. |
| **Dernières 48 h** | Courbe **Mesuré** comparée au **Profil type** (pointillés). | Un écart net signale un usage inhabituel. |
| **Recommandations** | Conseils chiffrés, avec **Économie estimée** en kWh/mois et en FCFA. | Exemples : consommation de veille élevée, consommation concentrée en soirée, pics inhabituels, données incomplètes, « Bravo, usage efficace ! ». |
| **Anomalies (7 jours)** | **Pic** (heure très au-dessus de l'habitude) et **Dérive nocturne** (veille anormale plusieurs nuits de suite). | « Aucune anomalie détectée » si tout va bien. |
| **Qualité des données** | Pourcentage de complétude, heures reçues sur heures attendues, part des heures à 0 kWh, trous de données. | Une complétude faible rend l'analyse moins fiable. |

**Barème FCFA utilisé** (progressif, par tranche mensuelle) :

| Tranche mensuelle | Prix du kWh |
|---|---|
| 0 à 110 kWh | 50 FCFA |
| 111 à 400 kWh | 79 FCFA |
| 401 à 800 kWh | 94 FCFA |
| Au-delà de 800 kWh | 99 FCFA |

En bas de l'onglet, **Poser une question à l'assistant** ouvre l'Assistant énergie avec l'analyse de ce kit.

---

## 5. Module Apprendre

### 5.1 L'écran Apprendre

L'onglet **Apprendre** (titre **Éducation énergétique**) contient :

- un compteur de progression : quiz réussis sur 7 et étapes cochées ;
- le sélecteur **Kit du banc** : le kit dont les mesures alimentent les fiches ;
- la liste des **Travaux pratiques** (TP1 à TP7) ;
- les **Éco-gestes** (classés par catégorie : Veille, Éclairage, Pointe, Froid, Habitudes, Coût) ;
- le **Glossaire** ;
- l'accès à l'**Assistant énergie**.

Sans kit enregistré, les fiches restent consultables, mais sans données en direct (« Ajoutez un kit (onglet Accueil) pour relier cette fiche à des mesures réelles. »).

### 5.2 Les 7 TP

| TP | Titre | Durée | Objectif |
|---|---|---|---|
| TP1 | Comprendre et mesurer l'énergie | 60 min | Distinguer puissance (W) et énergie (kWh), lire un compteur et sa constante d'impulsions, puis chiffrer une consommation en FCFA. |
| TP2 | Comprendre les circuits | 60 min | Identifier les conducteurs, comprendre le montage en parallèle des lignes et le rôle du disjoncteur, et calculer le courant appelé. |
| TP3 | Commander à distance par SMS | 45 min | Piloter une ligne par SMS sans Internet, comprendre l'accusé de réception et la sécurité par numéros autorisés. |
| TP4 | Comparer les usages | 90 min | Mesurer et comparer deux usages sur une même durée à partir des trames horaires du kit, puis extrapoler l'écart en kWh et en FCFA. |
| TP5 | Efficacité énergétique | 90 min | Mesurer la consommation de veille, comprendre la pointe du soir et interpréter le score d'efficacité calculé par l'IA. |
| TP6 | Internet des objets et données | 60 min | Comprendre la chaîne IoT du kit (capteur, modem GSM, SMS, application, serveur), décoder une trame et évaluer la qualité des données. |
| TP7 | Mini-projet d'apprenants | 180 min | Mener en équipe un projet complet : problème réel, mesure de référence, action, mesure après, présentation chiffrée des résultats. |

Données en direct proposées selon le TP :

| TP | Cartes en direct |
|---|---|
| TP1 | Compteur (constante, index initial, dernier relevé, dernière trame horaire) et **Calculatrice E = P × t**. |
| TP2 | **État des lignes du banc** (ON/OFF) et calculatrice avec le courant sous 220 V. |
| TP3 | Bouton **Ouvrir le kit (piloter les lignes)**. |
| TP4, TP7 | **Comparer Scénario A / B**. |
| TP5 | Mini-score d'efficacité et **Comparer Scénario A / B**. |
| TP6 | **Trame décodée** (trame brute, date, créneau, énergie, trames stockées, complétude) et **Ouvrir l'analyse IA du kit**. |

### 5.3 Déroulé d'une séance de TP type (formateur)

**Avant la séance**

1. Vérifiez que le kit du banc est ajouté, configuré et verrouillé (section 3.3).
2. Dans **Apprendre**, choisissez le bon kit dans **Kit du banc**.
3. Pour TP4, TP5, TP6 et TP7 : vérifiez que des trames horaires arrivent (onglet **Analyse IA** du kit, ou carte **Trame décodée** du TP6).

**Pendant la séance**

1. **Ouvrir la fiche** : touchez le TP dans la liste. La fiche affiche l'**Objectif**, la durée et l'encadré **À retenir**.
2. **Données en direct** : montrez aux apprenants les mesures réelles du kit (voir le tableau ci-dessus).
3. **Déroulé : cochez au fur et à mesure** : touchez chaque étape une fois réalisée. Le compteur (par exemple 3/6) avance. Les coches sont **mémorisées** : on peut reprendre plus tard. Pour tout remettre à zéro, utilisez l'icône **Décocher toutes les étapes** en haut de la fiche.
4. **Scénarios A / B** (TP4, TP5, TP7) :
   1. Installez la situation A (l'encadré indique laquelle, par exemple pour TP4 : L1 et L2 avec ampoules classiques ; pour TP5 : appareils en veille sur L3 et L4).
   2. Dans **Scénario A**, appuyez sur **Démarrer**. Le début est calé sur l'heure pleine la plus proche.
   3. Laissez fonctionner au moins une heure pleine, puis appuyez sur **Terminer**.
   4. Faites de même pour **Scénario B** (par exemple ampoules LED pour TP4, tout débranché pour TP5).
   5. Une fois les trames reçues, le résultat s'affiche : « B consomme … kWh/h de moins que A (… %) » et l'extrapolation sur un mois (5 h/jour × 30 j, à 79 FCFA/kWh).
   6. **Ajuster** permet de corriger les heures de début et de fin. **Effacer** supprime le scénario.

   > Les trames étant horaires, chaque scénario doit couvrir des **heures pleines**. Si des heures manquent, la mention « la comparaison est provisoire » apparaît.

5. **Compétences visées** : relisez-les avec le groupe en fin de séance.
6. **Quiz** : chaque apprenant appuie sur **Faire le quiz (n questions)**, répond à toutes les questions puis **Valider mes réponses**.
   - Les bonnes réponses et une explication s'affichent.
   - **70 %** de bonnes réponses sont nécessaires pour réussir (« Réussi ! Score enregistré. »).
   - Sinon : « Pas encore : relisez la fiche et réessayez », bouton **Recommencer**.
   - Le **Meilleur score** est conservé sur la fiche.
7. **Tuteur** : en cas de blocage, l'apprenant appuie sur **Demander à l'assistant sur ce TP** (section 6.4).

> Les coches, scores de quiz et scénarios sont enregistrés **sur le téléphone**. Si plusieurs apprenants partagent un même téléphone, ils partagent aussi cette progression.

---

## 6. Assistant énergie et tuteur de TP

### 6.1 Fonctionnement

L'Assistant énergie répond aux questions sur la consommation, la facture ENEO, les économies d'énergie et les TP.

- **En ligne** (« En ligne · serveur EnMKit ») : si le serveur est configuré et joignable.
- **Hors-ligne** (« Mode hors-ligne · conseils locaux ») : sinon. Les réponses sont alors construites à partir des recommandations de l'Analyse IA, des éco-gestes et du glossaire. Elles portent la mention **Réponse hors-ligne**.

On y accède depuis :

- **Apprendre > Assistant énergie** ;
- **Analyse IA > Poser une question à l'assistant** ;
- une fiche TP > **Demander à l'assistant sur ce TP**.

### 6.2 Activer le serveur (Réglages)

1. Ouvrez **Réglages > Serveur EnMKit (optionnel)**.
2. Appuyez sur **Configurer le serveur**.
3. **URL de l'API** : laissez l'adresse pré-remplie `https://api.enmkit.horus-lab.com` (une adresse en `https://` est obligatoire).
4. **Clé client (ck_…)** : saisissez la clé fournie à l'activation de votre établissement. Elle est masquée à l'écran.
5. Appuyez sur **Enregistrer**. Un test de connexion est lancé automatiquement.
6. Résultat attendu : **Connecté : [nom de l'établissement] · [n] kit(s)**.

Ensuite, **Tester la connexion** relance un test, **Supprimer la configuration** efface la clé. L'application reste entièrement utilisable sans serveur.

### 6.3 Utiliser l'assistant

1. Choisissez le public : **Apprenant**, **Propriétaire** ou **Formateur**.
2. Touchez une suggestion (**Comment réduire ma facture ?**, **Qu'est-ce que la veille ?**, **Combien vais-je payer ce mois ?**) ou écrivez votre question dans **Posez votre question…**.
3. L'icône de balayage en haut à droite (**Effacer la conversation**, visible dès qu'un message existe) vide l'échange.

**Quota** : le serveur limite le nombre de questions en ligne par établissement et par jour. Le nombre restant s'affiche : **Questions en ligne restantes aujourd'hui : n**. Une fois la limite atteinte, l'assistant répond hors-ligne jusqu'au lendemain.

### 6.4 Tuteur de TP

Depuis une fiche TP, **Demander à l'assistant sur ce TP** ouvre l'assistant intitulé **Tuteur du TPn**, avec le public **Apprenant** présélectionné.

- En ligne, l'assistant connaît le contenu du TP et **guide l'apprenant pas à pas, sans donner directement la réponse**. C'est voulu : il aide à raisonner.
- Hors-ligne, il répond avec les conseils locaux (pas de guidage spécifique au TP).

### 6.5 Messages de repli

| Message | Cause | Que faire |
|---|---|---|
| Pas de connexion au serveur : réponse hors-ligne. | Pas d'Internet ou serveur trop lent. | Vérifier les données mobiles ou le Wi-Fi. |
| Clé client refusée : vérifiez-la dans les Réglages. | Clé `ck_…` erronée ou désactivée. | Ressaisir la clé ; contacter EnMKit si besoin. |
| Assistant en ligne momentanément indisponible : réponse hors-ligne. | Service indisponible côté serveur. | Réessayer plus tard. |
| Limite de questions du jour atteinte : réponse hors-ligne. | Quota quotidien épuisé. | Attendre le lendemain. |
| Erreur du serveur : réponse hors-ligne. | Autre erreur. | Réessayer ; contacter le support si cela persiste. |

---

## 7. Aide et support

L'onglet **Aide** (titre **Aide & assistance**) permet d'écrire au support EnMKit. La demande part **par SMS**, et la réponse s'affiche dans la conversation.

1. **Votre besoin** : choisissez l'objet :
   - Configuration d'un numéro (puis **Quelle action ?** : Ajouter, Modifier ou Supprimer un numéro, et **Numéro concerné**) ;
   - Problème de réception de la consommation ;
   - Problème de commande d'une ligne ;
   - Kit injoignable ;
   - Autre demande.
2. **Kit concerné** : sélectionnez le kit.
3. **Précisions** : décrivez brièvement (facultatif).
4. Appuyez sur **Envoyer au support**. Confirmation : **Demande envoyée au support**.
5. Les échanges apparaissent dans **Conversation**. Répondez dans **Votre réponse**.

Alternative : **Continuer sur WhatsApp** ouvre WhatsApp avec le message préparé.

Quand le support répond, un **point rouge** apparaît sur l'icône Aide de la barre du bas.

La **FAQ** (Réglages > Aide > **Questions fréquentes (FAQ)**) couvre : Compte & Connexion, Appareil / Kit, QR & Configuration, Dépannage.

Contact écrit : contact@2metechsarl.org.

---

## 8. Réglages

| Section | Réglage | Détail |
|---|---|---|
| **Apparence** | Clair, Sombre, Auto | Auto suit le thème du téléphone. |
| **Couleur d'accent** | Palette de couleurs | Change la couleur principale de l'interface. |
| **Langue** | Français, English | Change toute l'interface, y compris les fiches TP. |
| **Sécurité** | **Code de sécurité** | Interrupteur. L'activer crée un code (4 chiffres minimum) et des questions de récupération. Le désactiver demande le code actuel. |
| | **Déverrouillage par empreinte** | Visible si le code est activé. Le code reste le secours. |
| | **Questions de récupération** | Définir ou modifier les deux questions. |
| | **Modifier le code d'accès** | Code actuel, nouveau code, confirmation. |
| **Serveur EnMKit (optionnel)** | URL de l'API, Clé client | Voir section 6.2. |
| **Aide** | Questions fréquentes (FAQ) | Voir section 7. |
| **À propos** | Application, Version | Informations sur l'application. |

---

## 9. Dépannage

### SMS non reçus ou kit qui ne répond pas

1. Vérifiez que l'application a bien l'autorisation **SMS** (Paramètres Android > Applications > EnMKit Banc > Autorisations).
2. Vérifiez le crédit SMS et le réseau **du téléphone** et **du kit**.
3. Vérifiez le **Numéro du kit** dans l'onglet **Config** (bon numéro, sans faute de frappe).
4. Vérifiez que votre téléphone fait partie des **Numéros autorisés** du kit : le kit n'obéit qu'à ces numéros.
5. Patientez : une réponse peut prendre plusieurs minutes. Elle sera reconnue même si l'application est fermée.
6. Onglet **Lignes**, carte **Connexion du kit** : appuyez sur **Tester** pour vérifier que le kit répond.
7. Si le problème persiste : onglet **Aide**, objet « Kit injoignable ».

### L'Analyse IA reste vide

- Le message **Pas encore de trames horaires** signifie qu'aucune trame `JJ/MM/AA;HH;KWH` n'a été reçue.
- Les trames doivent provenir du **numéro du kit** enregistré dans l'application.
- La demande de consommation (onglet Conso) ne remplit pas l'Analyse IA : seules les trames horaires le font.
- Tirez l'écran vers le bas pour actualiser.
- Avec moins de 72 heures de données, l'analyse s'affiche mais reste approximative.

### Comparaison A / B qui n'aboutit pas

- Chaque scénario doit être **terminé** (bouton **Terminer**) et couvrir au moins une heure pleine.
- Le résultat attend l'arrivée des trames de ce créneau (« En attente des trames horaires de ce créneau… »).
- Vérifiez que le bon kit est choisi dans **Kit du banc**.

### L'assistant reste en mode hors-ligne

1. Vérifiez qu'un serveur est configuré : **Réglages > Serveur EnMKit (optionnel)**.
2. Vérifiez l'URL (`https://api.enmkit.horus-lab.com`) et la clé `ck_…`.
3. Appuyez sur **Tester la connexion**. Attendu : **Connecté : …**.
4. Vérifiez la connexion Internet du téléphone (Wi-Fi ou données mobiles).
5. Lisez le message affiché sous le statut de l'assistant (tableau de la section 6.5).

### Quota de questions atteint

- Message : **Limite de questions du jour atteinte : réponse hors-ligne.**
- L'assistant en ligne revient le lendemain. En attendant, les réponses hors-ligne restent disponibles, ainsi que les fiches, éco-gestes et glossaire.
- Pour une séance avec beaucoup d'apprenants, préparez les questions clés à l'avance ou utilisez le tuteur pour les points de blocage seulement.

### Code oublié

Sur l'écran de saisie du code : **Code oublié ?**, répondez à vos questions de récupération, puis définissez un nouveau code. Si aucune question n'est configurée, contactez le support.

---

*2ME Technologies SARL · EnMKit · contact@2metechsarl.org · https://www.2metechsarl.org*
