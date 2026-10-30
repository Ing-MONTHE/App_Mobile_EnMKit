/// Internationalisation EnMKit : catalogue de traductions centralisé.
///
/// Une seule source de vérité pour tous les textes de l'interface. Ajouter une
/// langue = ajouter une entrée dans [_catalog] pour chaque clé. La langue
/// courante vient de SettingsViewModel (persistée), via [tProvider].
class AppStrings {
  AppStrings(this.locale);

  /// Code de langue courant ('fr', 'en').
  final String locale;

  /// Langues disponibles dans l'app.
  static const supported = ['fr', 'en'];

  static const Map<String, String> languageNames = {
    'fr': 'Français',
    'en': 'English',
  };

  static const Map<String, String> languageFlags = {
    'fr': '🇫🇷',
    'en': '🇬🇧',
  };

  /// Clés des questions mémo prédéfinies (récupération du code). La valeur
  /// stockée en base est cette clé ; le libellé affiché vient de [_catalog].
  static const List<String> securityQuestionKeys = [
    'recovery.q.city',
    'recovery.q.pet',
    'recovery.q.school',
    'recovery.q.mother',
    'recovery.q.dish',
    'recovery.q.hero',
  ];

  /// Récupère une traduction. Repli : fr → clé brute.
  String t(String key) {
    final entry = _catalog[key];
    if (entry == null) return key;
    return entry[locale] ?? entry['fr'] ?? key;
  }

  /// Traduction avec substitution simple {0}, {1}…
  String tf(String key, List<Object> args) {
    var s = t(key);
    for (var i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', '${args[i]}');
    }
    return s;
  }

  static const Map<String, Map<String, String>> _catalog = {
    // --- Général --------------------------------------------------------------
    'app.tagline': {
      'fr': 'Gestion intelligente de l\'énergie',
      'en': 'Smart energy management',
    },
    'common.add': {'fr': 'Ajouter', 'en': 'Add'},
    'common.cancel': {'fr': 'Annuler', 'en': 'Cancel'},
    'common.save': {'fr': 'Enregistrer', 'en': 'Save'},
    'common.confirm': {'fr': 'Confirmer', 'en': 'Confirm'},
    'common.delete': {'fr': 'Supprimer', 'en': 'Delete'},
    'common.retry': {'fr': 'Réessayer', 'en': 'Retry'},
    'common.loading': {'fr': 'Chargement…', 'en': 'Loading…'},
    'common.soon': {'fr': 'Bientôt', 'en': 'Soon'},
    'common.continue': {'fr': 'Continuer', 'en': 'Continue'},
    'common.skip': {'fr': 'Passer', 'en': 'Skip'},
    'access.skipForNow': {'fr': "Passer pour l'instant", 'en': 'Skip for now'},
    'support.topic.numberConfig': {'fr': "Configuration d'un numéro", 'en': 'Number setup'},
    'support.topic.consumption': {'fr': 'Problème de réception de la consommation', 'en': 'Consumption not received'},
    'support.topic.lineControl': {'fr': "Problème de commande d'une ligne", 'en': 'Line control problem'},
    'support.topic.unreachable': {'fr': 'Kit injoignable', 'en': 'Kit unreachable'},
    'support.topic.other': {'fr': 'Autre demande', 'en': 'Other request'},
    'support.action.add': {'fr': 'Ajouter un numéro', 'en': 'Add a number'},
    'support.action.edit': {'fr': 'Modifier un numéro', 'en': 'Change a number'},
    'support.action.remove': {'fr': 'Supprimer un numéro', 'en': 'Remove a number'},

    // --- Navigation -----------------------------------------------------------
    'nav.home': {'fr': 'Accueil', 'en': 'Home'},
    'nav.settings': {'fr': 'Réglages', 'en': 'Settings'},

    // --- Accès (PIN) ----------------------------------------------------------
    'access.welcome': {'fr': 'Bon retour 👋', 'en': 'Welcome back 👋'},
    'access.create': {'fr': 'Créez votre code', 'en': 'Create your code'},
    'access.confirm': {'fr': 'Confirmez le code', 'en': 'Confirm the code'},
    'access.enterToContinue': {
      'fr': 'Saisissez votre code pour continuer.',
      'en': 'Enter your code to continue.',
    },
    'access.willProtect': {
      'fr': 'Ce code protégera l\'accès à l\'application.',
      'en': 'This code will protect access to the app.',
    },
    'access.reenter': {
      'fr': 'Saisissez à nouveau le même code.',
      'en': 'Enter the same code again.',
    },
    'access.wrong': {'fr': 'Code incorrect', 'en': 'Wrong code'},
    'access.tooShort': {
      'fr': 'Le code doit contenir exactement 4 chiffres',
      'en': 'The code must be exactly 4 digits',
    },
    'access.mismatch': {
      'fr': 'Les deux codes ne correspondent pas',
      'en': 'The two codes do not match',
    },
    'access.oldWrong': {'fr': 'Ancien code incorrect', 'en': 'Old code is wrong'},
    'access.newTooShort': {
      'fr': 'Le nouveau code doit contenir exactement 4 chiffres',
      'en': 'The new code must be exactly 4 digits',
    },
    'access.forgot': {'fr': 'Code oublié ?', 'en': 'Forgot code?'},
    'access.useBiometric': {
      'fr': 'Utiliser l\'empreinte',
      'en': 'Use fingerprint',
    },
    'access.biometricReason': {
      'fr': 'Confirmez votre identité pour déverrouiller EnMKit.',
      'en': 'Confirm your identity to unlock EnMKit.',
    },

    // --- Récupération : questions mémo ----------------------------------------
    'recovery.title': {
      'fr': 'Questions de récupération',
      'en': 'Recovery questions',
    },
    'recovery.subtitle': {
      'fr': 'En cas d\'oubli du code, ces questions vous permettront d\'en définir un nouveau.',
      'en': 'If you forget your code, these questions let you set a new one.',
    },
    'recovery.question': {'fr': 'Question', 'en': 'Question'},
    'recovery.choose': {'fr': 'Choisir une question…', 'en': 'Choose a question…'},
    'recovery.answer': {'fr': 'Votre réponse', 'en': 'Your answer'},
    'recovery.sameQuestion': {
      'fr': 'Choisissez deux questions différentes',
      'en': 'Choose two different questions',
    },
    'recovery.answersRequired': {
      'fr': 'Les deux réponses sont requises',
      'en': 'Both answers are required',
    },
    'recovery.saved': {
      'fr': 'Questions de récupération enregistrées ✓',
      'en': 'Recovery questions saved ✓',
    },
    'recovery.answerHint': {
      'fr': 'La casse et les espaces sont ignorés.',
      'en': 'Case and spaces are ignored.',
    },
    // Liste de questions prédéfinies.
    'recovery.q.city': {
      'fr': 'Quelle est votre ville de naissance ?',
      'en': 'What is your city of birth?',
    },
    'recovery.q.pet': {
      'fr': 'Quel était le nom de votre premier animal ?',
      'en': 'What was your first pet\'s name?',
    },
    'recovery.q.school': {
      'fr': 'Quel est le nom de votre école primaire ?',
      'en': 'What was the name of your primary school?',
    },
    'recovery.q.mother': {
      'fr': 'Quel est le nom de jeune fille de votre mère ?',
      'en': 'What is your mother\'s maiden name?',
    },
    'recovery.q.dish': {
      'fr': 'Quel est votre plat préféré ?',
      'en': 'What is your favorite dish?',
    },
    'recovery.q.hero': {
      'fr': 'Qui était votre héros d\'enfance ?',
      'en': 'Who was your childhood hero?',
    },

    // --- Code oublié (réinitialisation) ---------------------------------------
    'forgot.title': {'fr': 'Code oublié', 'en': 'Forgot code'},
    'forgot.subtitle': {
      'fr': 'Répondez à vos questions de récupération pour définir un nouveau code.',
      'en': 'Answer your recovery questions to set a new code.',
    },
    'forgot.newPin': {'fr': 'Nouveau code (4 chiffres)', 'en': 'New code (4 digits)'},
    'forgot.confirmPin': {'fr': 'Confirmer le code', 'en': 'Confirm the code'},
    'forgot.wrongAnswers': {'fr': 'Réponses incorrectes', 'en': 'Incorrect answers'},
    'forgot.success': {'fr': 'Code réinitialisé ✓', 'en': 'Code reset ✓'},
    'forgot.noQuestions': {
      'fr': 'Aucune question de récupération n\'est configurée sur cet appareil.',
      'en': 'No recovery questions are set on this device.',
    },
    'forgot.reset': {'fr': 'Réinitialiser le code', 'en': 'Reset code'},

    // --- Empreinte (proposition) ----------------------------------------------
    'biometric.proposeTitle': {
      'fr': 'Déverrouillage par empreinte',
      'en': 'Fingerprint unlock',
    },
    'biometric.proposeSub': {
      'fr': 'Ouvrez l\'app rapidement avec votre empreinte. Le code reste le secours.',
      'en': 'Open the app quickly with your fingerprint. The code stays as backup.',
    },
    'biometric.enable': {'fr': 'Activer l\'empreinte', 'en': 'Enable fingerprint'},
    'biometric.later': {'fr': 'Plus tard', 'en': 'Later'},

    // --- Kits -----------------------------------------------------------------
    'kits.hello': {'fr': 'Bonjour 👋', 'en': 'Hello 👋'},
    'kits.title': {'fr': 'Mes kits', 'en': 'My kits'},
    'kits.park': {'fr': 'Mon parc', 'en': 'My fleet'},
    'kits.count': {'fr': 'kit', 'en': 'kit'},
    'kits.countPlural': {'fr': 'kits', 'en': 'kits'},
    'kits.configured': {'fr': '{0} configuré', 'en': '{0} set up'},
    'kits.configuredPlural': {'fr': '{0} configurés', 'en': '{0} set up'},
    'kits.pending': {'fr': '{0} en attente', 'en': '{0} pending'},
    'kits.empty.title': {
      'fr': 'Aucun kit pour le moment',
      'en': 'No kits yet',
    },
    'kits.empty.msg': {
      'fr': 'Ajoutez votre premier kit pour le piloter par SMS.',
      'en': 'Add your first kit to control it via SMS.',
    },
    'kits.empty.action': {'fr': 'Ajouter un kit', 'en': 'Add a kit'},
    'kits.loading': {'fr': 'Chargement de vos kits…', 'en': 'Loading your kits…'},
    'kits.new': {'fr': 'Nouveau kit', 'en': 'New kit'},
    'kits.new.sub': {
      'fr': 'Donnez-lui un nom et le numéro de sa carte SIM.',
      'en': 'Give it a name and its SIM card number.',
    },
    'kits.name': {'fr': 'Nom du kit', 'en': 'Kit name'},
    'kits.name.hint': {'fr': 'Ex : Maison, Boutique…', 'en': 'E.g. Home, Shop…'},
    'kits.gsm': {'fr': 'Numéro du kit', 'en': 'Kit number'},
    'kits.gsm.required': {
      'fr': 'Le numéro du kit est obligatoire',
      'en': 'The kit number is required',
    },
    'kits.add.cta': {'fr': 'Ajouter le kit', 'en': 'Add the kit'},
    'kits.lineCount': {'fr': 'Nombre de lignes', 'en': 'Number of lines'},
    'kits.lineCount.custom': {'fr': 'Personnalisé', 'en': 'Custom'},
    'kits.configured.badge': {'fr': 'Configuré', 'en': 'Set up'},
    'kits.toConfigure': {'fr': 'À configurer', 'en': 'To set up'},
    'kits.noNumber': {'fr': 'Numéro non défini', 'en': 'No number set'},
    'kits.imported': {'fr': 'Kit « {0} » importé', 'en': 'Kit "{0}" imported'},
    'kits.importFailed': {
      'fr': 'Import impossible : {0}',
      'en': 'Import failed: {0}',
    },
    'kits.delete.title': {
      'fr': 'Supprimer ce kit ?',
      'en': 'Delete this kit?',
    },
    'kits.delete.msg': {
      'fr':
          '« {0} » et toutes ses données (lignes, accusés, consommation) seront définitivement supprimés. Cette action est irréversible.',
      'en':
          '"{0}" and all its data (lines, acknowledgements, consumption) will be permanently deleted. This action cannot be undone.',
    },
    'kits.deleted': {'fr': '« {0} » supprimé', 'en': '"{0}" deleted'},
    'kits.swipeHint': {
      'fr': 'Glissez une carte pour la supprimer',
      'en': 'Swipe a card to delete it',
    },

    // --- Détail kit / onglets -------------------------------------------------
    'tab.relays': {'fr': 'Lignes', 'en': 'Lines'},
    'tab.consumption': {'fr': 'Conso', 'en': 'Usage'},
    'tab.config': {'fr': 'Config', 'en': 'Config'},

    // --- Lignes ---------------------------------------------------------------
    'relays.active': {'fr': 'Actives', 'en': 'Active'},
    'relays.inactive': {'fr': 'Inactives', 'en': 'Inactive'},
    'relays.control': {'fr': 'Commande des lignes', 'en': 'Line commands'},
    'relays.loading': {'fr': 'Chargement des lignes…', 'en': 'Loading lines…'},
    'relays.empty.title': {'fr': 'Aucune ligne', 'en': 'No lines'},
    'relays.empty.msg': {
      'fr': 'Ajoutez une ligne pour la piloter par SMS.',
      'en': 'Add a line to control it via SMS.',
    },
    'relays.add': {'fr': 'Ajouter une ligne', 'en': 'Add a line'},
    'relays.add.sub': {
      'fr': 'Donnez-lui un nom pour la reconnaître.',
      'en': 'Give it a name to recognise it.',
    },
    'relays.name': {'fr': 'Nom de la ligne', 'en': 'Line name'},
    'relays.name.hint': {'fr': 'Ex : Salon, Pompe…', 'en': 'E.g. Living room, Pump…'},
    'relays.amperage': {'fr': 'Ampérage', 'en': 'Amperage'},
    'relays.add.cta': {'fr': 'Ajouter la ligne', 'en': 'Add the line'},
    'relays.edit': {'fr': 'Modifier la ligne', 'en': 'Edit line'},
    'relays.edit.sub': {
      'fr': 'Changez son nom.',
      'en': 'Change its name.',
    },
    'relays.delete': {'fr': 'Supprimer', 'en': 'Delete'},
    'relays.delete.confirm': {
      'fr': 'Supprimer cette ligne ?',
      'en': 'Delete this line?',
    },
    'relays.edit.confirm': {
      'fr': 'Enregistrer les modifications ?',
      'en': 'Save the changes?',
    },
    'relays.max': {
      'fr': 'Maximum {0} lignes par kit atteint',
      'en': 'Maximum of {0} lines per kit reached',
    },
    'relays.on': {'fr': 'En marche', 'en': 'On'},
    'relays.off': {'fr': 'Arrêtée', 'en': 'Off'},
    'relays.pending': {'fr': 'En attente…', 'en': 'Pending…'},
    'relays.failed': {'fr': 'Échec : {0}', 'en': 'Failed: {0}'},
    'relays.quickActions': {'fr': 'Actions rapides', 'en': 'Quick actions'},
    'relays.allOn': {'fr': 'Tout allumer', 'en': 'Turn all on'},
    'relays.allOff': {'fr': 'Tout éteindre', 'en': 'Turn all off'},

    // --- Statut de connexion du kit (pilotage conditionné à la config) -------
    'relays.locked': {
      'fr': 'Envoyez d\'abord la configuration au kit (onglet Config) pour piloter les lignes.',
      'en': 'Send the configuration to the kit first (Config tab) to control the lines.'
    },
    'relays.status.on.title': {
      'fr': 'Kit connecté',
      'en': 'Kit connected'
    },
    'relays.status.on.sub': {
      'fr': 'Configuration reçue par le kit : pilotage des lignes actif.',
      'en': 'Configuration received by the kit: line control active.'
    },
    'relays.status.off.title': {
      'fr': 'Kit non configuré',
      'en': 'Kit not configured'
    },
    'relays.status.off.sub': {
      'fr': 'Envoyez la configuration (onglet Config) pour activer le pilotage des lignes.',
      'en': 'Send the configuration (Config tab) to enable line control.'
    },

    // --- Historique des accusés de réception (par ligne) ---------------------
    'relays.history': {'fr': 'Confirmations', 'en': 'Confirmations'},
    'relays.history.title': {
      'fr': 'Confirmation de la commande',
      'en': 'Command confirmation'
    },
    'relays.history.sub': {
      'fr': 'Confirmations renvoyées par le kit pour cette ligne.',
      'en': 'Confirmations sent back by the kit for this line.'
    },
    'relays.history.empty': {
      'fr': 'Aucune confirmation pour le moment.\nElles apparaîtront ici dès que le kit confirmera une commande.',
      'en': 'No confirmation yet.\nThey will appear here once the kit confirms a command.'
    },
    'relays.history.on': {'fr': 'alimenté(e)', 'en': 'powered on'},
    'relays.history.off': {'fr': 'désalimenté(e)', 'en': 'powered off'},
    // Phrase complète : nom de la ligne + état (ex. « salon1 est alimenté(e) »).
    'relays.history.line.on': {
      'fr': '{0} est alimenté(e)',
      'en': '{0} is powered on'
    },
    'relays.history.line.off': {
      'fr': '{0} est désalimenté(e)',
      'en': '{0} is powered off'
    },
    'relays.history.today': {'fr': "Aujourd'hui", 'en': 'Today'},
    'relays.history.yesterday': {'fr': 'Hier', 'en': 'Yesterday'},

    // --- Connexion / joignabilité du kit -------------------------------------
    'kit.connection': {'fr': 'Connexion du kit', 'en': 'Kit connection'},
    'kit.test': {'fr': 'Tester', 'en': 'Test'},
    'kit.helloSent': {'fr': 'Test envoyé au kit…', 'en': 'Test sent to the kit…'},
    'kit.checking': {
      'fr': 'Vérification du kit…',
      'en': 'Checking the kit…',
    },
    'kit.reachable': {'fr': 'Kit joignable', 'en': 'Kit reachable'},
    'kit.unreachable': {
      'fr': 'Kit injoignable. Vérifiez que sa carte SIM a du réseau et du crédit SMS.',
      'en': 'Kit unreachable. Check that its SIM has network and SMS credit.',
    },
    'kit.unknown': {
      'fr': 'Statut inconnu. Lancez un test.',
      'en': 'Unknown status. Run a test.',
    },

    // --- Consommation ---------------------------------------------------------
    'cons.refresh': {
      'fr': 'Vérifier votre\nconsommation électrique',
      'en': 'Check your\nelectricity usage',
    },
    'cons.lastMeasure': {'fr': 'Dernière mesure', 'en': 'Last reading'},
    'cons.noMeasure': {'fr': 'Aucune mesure', 'en': 'No reading'},
    'cons.history': {'fr': 'Historique', 'en': 'History'},
    'cons.trend': {'fr': 'Évolution', 'en': 'Trend'},
    'cons.empty.title': {'fr': 'Aucune donnée', 'en': 'No data'},
    'cons.empty.msg': {
      'fr': 'Appuyez sur « Vérifier votre consommation électrique » pour interroger le kit.',
      'en': 'Tap "Check your electricity usage" to query the kit.',
    },
    'cons.requestSent': {'fr': 'Demande envoyée au kit…', 'en': 'Request sent to the kit…'},
    'cons.waiting': {
      'fr': 'En attente de la réponse du kit…',
      'en': 'Waiting for the kit to reply…',
    },
    'cons.received': {
      'fr': 'Nouvelle mesure reçue',
      'en': 'New reading received',
    },
    'cons.timeout': {
      'fr': 'Aucune réponse du kit. Vérifiez le réseau/numéro et réessayez.',
      'en': 'No reply from the kit. Check the network/number and retry.',
    },

    // --- Config kit -----------------------------------------------------------
    'config.kitInfo': {'fr': 'Informations du kit', 'en': 'Kit information'},
    'config.name': {'fr': 'Nom', 'en': 'Name'},
    'config.gsm': {'fr': 'Numéro du kit', 'en': 'Kit number'},
    'config.notSet': {'fr': 'Non défini', 'en': 'Not set'},
    'config.meter': {'fr': 'Compteur', 'en': 'Meter'},
    'config.pulses': {'fr': 'Impulsion par kWh', 'en': 'Pulses per kWh'},
    'config.initialCons': {'fr': 'Consommation initiale', 'en': 'Initial consumption'},
    'config.allowed': {'fr': 'Numéros autorisés', 'en': 'Allowed numbers'},
    'config.noAllowed': {'fr': 'Aucun numéro autorisé', 'en': 'No allowed numbers'},
    'config.sendConfig': {
      'fr': 'Envoyer la configuration au kit',
      'en': 'Send configuration to the kit',
    },
    'config.genQr': {'fr': 'Générer le QR Code', 'en': 'Generate QR Code'},
    'config.editInfo': {
      'fr': 'Informations du kit',
      'en': 'Kit information',
    },
    'config.editInfo.sub': {
      'fr': 'Modifiez le nom et le numéro du kit.',
      'en': 'Edit the name and kit number.',
    },
    'config.editInfo.confirm': {
      'fr': 'Enregistrer les modifications ?',
      'en': 'Save the changes?',
    },
    'config.rename': {'fr': 'Renommer le kit', 'en': 'Rename the kit'},
    'config.rename.sub': {
      'fr': 'Choisissez un nom facile à reconnaître.',
      'en': 'Pick an easy-to-recognize name.',
    },
    'config.meter.sub': {
      'fr': 'Impulsions du compteur et relevé de départ.',
      'en': 'Meter pulses and starting reading.',
    },
    'config.pulses.label': {'fr': 'Impulsion par kWh', 'en': 'Pulses per kWh'},
    'config.initial.label': {
      'fr': 'Consommation initiale (kWh)',
      'en': 'Initial usage (kWh)',
    },
    'config.meterTitle': {'fr': 'Paramètres compteur', 'en': 'Meter settings'},
    'config.gsm.hint': {'fr': 'Ex : 6XX XX XX XX', 'en': 'E.g. 6XX XX XX XX'},
    'config.pulses.hint': {'fr': 'Ex : 1000', 'en': 'E.g. 1000'},
    'config.pulses.invalid': {
      'fr': "L'impulsion par kWh doit être un nombre entier supérieur à 0.",
      'en': 'Pulses per kWh must be a whole number greater than 0.',
    },
    'config.initial.hint': {'fr': 'Ex : 0', 'en': 'E.g. 0'},
    'config.allowed.title': {'fr': 'Numéro autorisé', 'en': 'Allowed number'},
    'config.allowed.sub': {
      'fr': 'Ce numéro pourra commander le kit par SMS.',
      'en': 'This number will be able to control the kit via SMS.',
    },
    'config.phone': {'fr': 'Numéro de téléphone', 'en': 'Phone number'},
    'config.deleteNumber.confirm': {
      'fr': 'Retirer ce numéro autorisé ?',
      'en': 'Remove this allowed number?',
    },
    'config.configSent': {
      'fr': 'Configuration envoyée au kit',
      'en': 'Configuration sent to the kit',
    },
    'config.waitingAck': {
      'fr': 'En attente de la confirmation du kit…',
      'en': 'Waiting for the kit to confirm…',
    },
    'config.ackOk': {
      'fr': 'Configuration confirmée par le kit',
      'en': 'Configuration confirmed by the kit',
    },
    'config.sentWaiting': {
      'fr': 'Configuration envoyée. En attente du retour du kit…',
      'en': 'Configuration sent. Waiting for the kit to reply…',
    },
    'config.state.waitingTitle': {
      'fr': 'Configuration envoyée',
      'en': 'Configuration sent',
    },
    'config.state.waitingBody': {
      'fr':
          'Le kit n\'a pas encore répondu. Sa réponse peut prendre plusieurs minutes : elle sera reconnue même si vous quittez l\'application.',
      'en':
          'The kit has not replied yet. It can take several minutes; the reply is recognised even if you leave the app.',
    },
    'config.state.badgeWaiting': {'fr': 'EN COURS', 'en': 'PENDING'},
    'config.state.okTitle': {
      'fr': 'Le retour du kit correspond',
      'en': 'The kit\'s reply matches',
    },
    'config.state.okBody': {
      'fr':
          'Le kit a renvoyé exactement ce qui lui a été envoyé. Validez pour clore la configuration. Elle sera alors verrouillée.',
      'en':
          'The kit echoed back exactly what was sent. Confirm to close the configuration. It will then be locked.',
    },
    'config.state.badgeOk': {'fr': 'OK', 'en': 'OK'},
    'config.state.finalizeCta': {
      'fr': 'Valider et verrouiller',
      'en': 'Confirm and lock',
    },
    'config.state.lockedTitle': {
      'fr': 'Configuration verrouillée',
      'en': 'Configuration locked',
    },
    'config.state.lockedBody': {
      'fr':
          'La configuration est close et ne peut plus être modifiée ni renvoyée au kit. Restent disponibles : le pilotage des lignes et la consommation.',
      'en':
          'The configuration is closed and can no longer be changed or resent. Line control and consumption remain available.',
    },
    'config.state.badgeLocked': {'fr': 'VERROUILLÉ', 'en': 'LOCKED'},
    'config.locked.hint': {
      'fr': 'Verrouillé · configuration close',
      'en': 'Locked · configuration closed',
    },
    'kits.toConfirm': {'fr': '{0} à valider', 'en': '{0} to confirm'},
    'nav.help': {'fr': 'Aide', 'en': 'Help'},
    'help.title': {'fr': 'Aide & assistance', 'en': 'Help & support'},
    'help.sub': {
      'fr':
          'Exprimez votre besoin : il part au support par SMS, et sa réponse s\'affiche ici.',
      'en':
          'Describe your need: it is sent to support by SMS, and their reply appears here.',
    },
    'help.q.topic': {'fr': 'Votre besoin', 'en': 'Your need'},
    'help.q.action': {'fr': 'Quelle action ?', 'en': 'Which action?'},
    'help.q.number': {'fr': 'Numéro concerné', 'en': 'Number concerned'},
    'help.q.kit': {'fr': 'Kit concerné', 'en': 'Kit concerned'},
    'help.q.details': {'fr': 'Précisions', 'en': 'Details'},
    'help.q.details.hint': {
      'fr': 'Décrivez brièvement (facultatif)',
      'en': 'Briefly describe (optional)',
    },
    'help.send': {'fr': 'Envoyer au support', 'en': 'Send to support'},
    'help.whatsapp': {
      'fr': 'Continuer sur WhatsApp',
      'en': 'Continue on WhatsApp',
    },
    'help.sent': {
      'fr': 'Demande envoyée au support',
      'en': 'Request sent to support',
    },
    'help.sendFailed': {
      'fr': 'Envoi impossible. Vérifiez le réseau et le crédit SMS.',
      'en': 'Could not send. Check network and SMS credit.',
    },
    'help.thread': {'fr': 'Conversation', 'en': 'Conversation'},
    'help.threadEmpty': {
      'fr':
          'Aucun échange pour l\'instant. Votre demande et les réponses du support apparaîtront ici.',
      'en':
          'No messages yet. Your request and support replies will appear here.',
    },
    'help.reply': {'fr': 'Votre réponse', 'en': 'Your reply'},
    'help.reply.hint': {'fr': 'Écrire un message…', 'en': 'Write a message…'},
    'config.finalizeCheck': {
      'fr':
          'Vérifiez que ces informations sont correctes. Si l\'une est erronée, annulez et corrigez la configuration avant de valider.',
      'en':
          'Check that these details are correct. If any is wrong, cancel and fix the configuration before confirming.',
    },
    'config.finalizeWarning': {
      'fr':
          'Cette validation est définitive : les mises à jour de configuration seront closes, et toute modification ultérieure devra passer par les administrateurs.',
      'en':
          'This confirmation is final: configuration updates will be closed, and any later change will have to go through the administrators.',
    },
    'config.finalizeTitle': {
      'fr': 'Le kit a bien reçu la configuration',
      'en': 'The kit received the configuration',
    },
    'config.finalizeBody': {
      'fr':
          'Le kit a renvoyé exactement ce qui lui a été envoyé. Validez pour clore la configuration.',
      'en':
          'The kit echoed back exactly what was sent. Confirm to close the configuration.',
    },
    'config.finalizeCta': {
      'fr': 'OK',
      'en': 'OK',
    },
    'config.pendingChip': {
      'fr': 'À valider',
      'en': 'To confirm',
    },
    'config.pendingTitle': {
      'fr': 'Configuration à valider',
      'en': 'Configuration to confirm',
    },
    'config.pendingBody': {
      'fr':
          'Le kit a confirmé la configuration reçue. Il ne reste qu\'à la valider pour la clore.',
      'en':
          'The kit confirmed the configuration it received. Only the final confirmation is missing.',
    },
    'config.finalized': {
      'fr': 'Configuration terminée',
      'en': 'Configuration completed',
    },
    'config.finalizeError': {
      'fr': 'Échec de l\'envoi de la validation : {0}',
      'en': 'Could not send the confirmation: {0}',
    },
    'config.ackTimeout': {
      'fr': 'Envoyée, mais aucune confirmation reçue. Vérifiez le kit.',
      'en': 'Sent, but no confirmation received. Check the kit.',
    },
    'config.sendError': {'fr': 'Erreur envoi : {0}', 'en': 'Send error: {0}'},
    'config.preview.title': {
      'fr': 'Vérifier la configuration',
      'en': 'Review configuration',
    },
    'config.preview.sub': {
      'fr': 'Voici ce qui sera envoyé au kit par SMS. Validez pour envoyer.',
      'en': 'Here is what will be sent to the kit by SMS. Confirm to send.',
    },
    'config.preview.send': {'fr': 'Envoyer au kit', 'en': 'Send to kit'},
    'config.preview.n1': {'fr': 'Numéro 1', 'en': 'Number 1'},
    'config.preview.n2': {'fr': 'Numéro 2', 'en': 'Number 2'},
    'config.preview.en': {'fr': 'Conso initiale', 'en': 'Initial consumption'},
    'config.preview.ip': {'fr': 'Impulsion par kWh', 'en': 'Pulses per kWh'},
    'config.preview.none': {'fr': 'aucun', 'en': 'none'},
    'config.numbers.saved': {
      'fr': 'Numéros enregistrés',
      'en': 'Numbers saved',
    },

    // --- Réglages -------------------------------------------------------------
    'settings.title': {'fr': 'Réglages', 'en': 'Settings'},
    'settings.subtitle': {
      'fr': 'Personnalisez votre expérience',
      'en': 'Personalize your experience',
    },
    'settings.appearance': {'fr': 'Apparence', 'en': 'Appearance'},
    'settings.light': {'fr': 'Clair', 'en': 'Light'},
    'settings.dark': {'fr': 'Sombre', 'en': 'Dark'},
    'settings.auto': {'fr': 'Auto', 'en': 'Auto'},
    'settings.accent': {'fr': 'Couleur d\'accent', 'en': 'Accent color'},
    'settings.accent.sub': {
      'fr': 'Donnez votre style à l\'application',
      'en': 'Give the app your own style',
    },
    'settings.language': {'fr': 'Langue', 'en': 'Language'},
    'settings.security': {'fr': 'Sécurité', 'en': 'Security'},
    'settings.security.enable': {'fr': 'Code de sécurité', 'en': 'Security code'},
    'settings.security.enable.sub': {
      'fr': 'Protéger l\'ouverture de l\'app par un code',
      'en': 'Protect app launch with a code',
    },
    'settings.security.create.title': {
      'fr': 'Activer le code de sécurité',
      'en': 'Enable security code',
    },
    'settings.security.create.sub': {
      'fr': 'Choisissez un code à 4 chiffres.',
      'en': 'Choose a 4-digit code.',
    },
    'settings.security.disable.title': {
      'fr': 'Désactiver le code',
      'en': 'Disable the code',
    },
    'settings.security.disable.sub': {
      'fr': 'Saisissez votre code actuel pour confirmer.',
      'en': 'Enter your current code to confirm.',
    },
    'settings.security.enabled': {
      'fr': 'Code de sécurité activé ✓',
      'en': 'Security code enabled ✓',
    },
    'settings.security.disabled': {
      'fr': 'Code de sécurité désactivé',
      'en': 'Security code disabled',
    },
    'settings.help': {'fr': 'Aide', 'en': 'Help'},
    'settings.help.faq': {
      'fr': 'Questions fréquentes (FAQ)',
      'en': 'Frequently asked questions (FAQ)',
    },
    'settings.changePin': {
      'fr': 'Modifier le code d\'accès',
      'en': 'Change access code',
    },
    'settings.changePin.title': {'fr': 'Modifier le code', 'en': 'Change the code'},
    'settings.changePin.sub': {
      'fr': 'Choisissez un nouveau code à 4 chiffres.',
      'en': 'Choose a new 4-digit code.',
    },
    'settings.currentPin': {'fr': 'Code actuel', 'en': 'Current code'},
    'settings.newPin': {'fr': 'Nouveau code', 'en': 'New code'},
    'settings.confirmPin': {'fr': 'Confirmer le code', 'en': 'Confirm the code'},
    'settings.pinUpdated': {'fr': 'Code mis à jour ✓', 'en': 'Code updated ✓'},
    'settings.biometric': {
      'fr': 'Déverrouillage par empreinte',
      'en': 'Fingerprint unlock',
    },
    'settings.biometric.sub': {
      'fr': 'Ouvrir l\'app avec votre empreinte (le code reste le secours).',
      'en': 'Open the app with your fingerprint (the code stays as backup).',
    },
    'settings.biometric.unavailable': {
      'fr': 'Aucune empreinte enregistrée sur cet appareil.',
      'en': 'No fingerprint enrolled on this device.',
    },
    'settings.recovery': {
      'fr': 'Questions de récupération',
      'en': 'Recovery questions',
    },
    'settings.recovery.sub': {
      'fr': 'Définir ou modifier les questions en cas d\'oubli du code.',
      'en': 'Set or change the questions in case you forget the code.',
    },
    'settings.about': {'fr': 'À propos', 'en': 'About'},
    'settings.app': {'fr': 'Application', 'en': 'Application'},
    'settings.version': {'fr': 'Version', 'en': 'Version'},

    // --- Scan / QR ------------------------------------------------------------
    'scan.title': {'fr': 'Scanner un kit', 'en': 'Scan a kit'},
    'scan.hint': {
      'fr': 'Placez le QR Code du kit dans le cadre',
      'en': 'Place the kit QR Code inside the frame',
    },
    'qr.title': {'fr': 'QR Code du kit', 'en': 'Kit QR Code'},
    'qr.scanToImport': {
      'fr': 'Scannez pour importer ce kit',
      'en': 'Scan to import this kit',
    },
    'qr.share': {'fr': 'Partager le QR Code', 'en': 'Share QR Code'},
    'qr.shareText': {
      'fr': 'Configuration de mon kit EnMKit 🔌',
      'en': 'My EnMKit kit configuration 🔌',
    },
    'qr.error': {'fr': 'Erreur : {0}', 'en': 'Error: {0}'},

    // --- Onboarding (tutoriel d'accueil) -------------------------------------
    'onb.skip': {'fr': 'Passer', 'en': 'Skip'},
    'onb.next': {'fr': 'Suivant', 'en': 'Next'},
    'onb.start': {'fr': 'Commencer', 'en': 'Get started'},
    'onb.1.title': {
      'fr': 'Pilotez vos kits à distance',
      'en': 'Control your kits remotely',
    },
    'onb.1.desc': {
      'fr': 'Commandez vos lignes électriques par SMS, où que vous soyez, même sans Internet.',
      'en': 'Switch your electrical lines by SMS, anywhere, even without Internet.',
    },
    'onb.2.title': {
      'fr': 'Suivez votre consommation',
      'en': 'Track your consumption',
    },
    'onb.2.desc': {
      'fr': 'Consultez la consommation de chaque kit et gardez un historique clair.',
      'en': 'Check each kit\'s consumption and keep a clear history.',
    },
    'onb.3.title': {
      'fr': 'Sécurisé et multi-kits',
      'en': 'Secure and multi-kit',
    },
    'onb.3.desc': {
      'fr': 'Protégez l\'application par un code si vous le souhaitez. Gérez tout votre parc depuis un seul endroit.',
      'en': 'Protect the application with a code if you wish. Manage your whole fleet from one place.',
    },
    // --- Analyse IA (trames horaires, moteur hors-ligne) ---------------------
    'tab.analysis': {'fr': 'Analyse IA', 'en': 'AI analysis'},
    'ai.empty.title': {
      'fr': 'Pas encore de trames horaires',
      'en': 'No hourly frames yet',
    },
    'ai.empty.msg': {
      'fr': 'Le kit envoie sa consommation heure par heure par SMS, sous la forme '
          '« JJ/MM/AA;HH;KWH » (ex. 27/06/26;09;0.12 = 0,12 kWh entre 9 h et '
          '10 h). Dès les premières trames reçues, l\'analyse s\'affiche ici : '
          'score, prévisions en FCFA, anomalies et conseils, calculés sur le '
          'téléphone, sans Internet.',
      'en': 'The kit sends its consumption hour by hour by SMS, as '
          '"DD/MM/YY;HH;KWH" lines (e.g. 27/06/26;09;0.12 = 0.12 kWh between '
          '9:00 and 10:00). As soon as the first frames arrive, the analysis '
          'shows up here: score, FCFA forecasts, anomalies and advice, '
          'computed on the phone, without Internet.',
    },
    'ai.offline': {
      'fr': 'Calculé sur le téléphone, sans Internet',
      'en': 'Computed on the phone, no Internet needed',
    },
    'ai.score': {'fr': 'Score d\'efficacité', 'en': 'Efficiency score'},
    'ai.grade': {'fr': 'Note {0}', 'en': 'Grade {0}'},
    'ai.lastFrame': {'fr': 'Dernière trame : {0}', 'en': 'Latest frame: {0}'},
    'ai.limited': {
      'fr': 'Peu de données : l\'analyse s\'affinera après quelques jours de trames.',
      'en': 'Little data so far: the analysis will sharpen after a few days of frames.',
    },
    'ai.today': {'fr': 'Aujourd\'hui (prévu)', 'en': 'Today (forecast)'},
    'ai.month': {'fr': 'Ce mois (prévu)', 'en': 'This month (forecast)'},
    'ai.avgDaily': {'fr': 'Moyenne / jour', 'en': 'Average / day'},
    'ai.baseLoad': {'fr': 'Veille (nuit)', 'en': 'Standby (night)'},
    'ai.peakHour': {'fr': 'Heure de pointe', 'en': 'Peak hour'},
    'ai.trend': {'fr': 'Tendance 7 j', 'en': '7-day trend'},
    'ai.penalties': {
      'fr': 'Pénalités : veille {0} · pointe {1} · tendance {2} · anomalies {3}',
      'en': 'Penalties: standby {0} · peak {1} · trend {2} · anomalies {3}',
    },
    'ai.chart.title': {'fr': 'Dernières 48 h', 'en': 'Last 48 h'},
    'ai.chart.actual': {'fr': 'Mesuré', 'en': 'Measured'},
    'ai.chart.typical': {'fr': 'Profil type', 'en': 'Typical profile'},
    'ai.anomalies': {'fr': 'Anomalies (7 jours)', 'en': 'Anomalies (7 days)'},
    'ai.anomalies.none': {
      'fr': 'Aucune anomalie détectée sur les 7 derniers jours.',
      'en': 'No anomaly detected over the last 7 days.',
    },
    'ai.anomaly.spike': {
      'fr': 'Pic : {0} kWh (habituel {1} kWh)',
      'en': 'Spike: {0} kWh (usual {1} kWh)',
    },
    'ai.anomaly.drift': {
      'fr': 'Dérive nocturne : {0} kWh/h (veille {1} kWh/h)',
      'en': 'Night drift: {0} kWh/h (standby {1} kWh/h)',
    },
    'ai.quality': {'fr': 'Qualité des données', 'en': 'Data quality'},
    'ai.quality.received': {
      'fr': '{0} / {1} heures reçues',
      'en': '{0} / {1} hours received',
    },
    'ai.quality.zero': {'fr': 'Heures à 0 kWh : {0} %', 'en': 'Hours at 0 kWh: {0}%'},
    'ai.quality.noGaps': {'fr': 'Aucun trou de données.', 'en': 'No data gap.'},
    'ai.quality.gap': {'fr': '{0} → {1} ({2} h)', 'en': '{0} → {1} ({2} h)'},
    'ai.recos': {'fr': 'Recommandations', 'en': 'Recommendations'},
    'ai.saving': {
      'fr': 'Économie estimée : {0} kWh/mois ≈ {1} FCFA',
      'en': 'Estimated saving: {0} kWh/month ≈ {1} FCFA',
    },
    'ai.assistant': {
      'fr': 'Poser une question à l\'assistant',
      'en': 'Ask the assistant',
    },

    // --- Navigation : module Éducation ---------------------------------------
    'nav.learn': {'fr': 'Apprendre', 'en': 'Learn'},

    // --- Éducation énergétique -----------------------------------------------
    'edu.title': {'fr': 'Éducation énergétique', 'en': 'Energy education'},
    'edu.subtitle': {
      'fr': 'Smart Home Learning Lab : 7 travaux pratiques sur le banc EnMKit '
          '(L1-L2 ampoules, L3-L4 prises).',
      'en': 'Smart Home Learning Lab: 7 practical labs on the EnMKit bench '
          '(L1-L2 bulbs, L3-L4 sockets).',
    },
    'edu.stats': {
      'fr': '{0}/7 quiz réussis · {1} étapes cochées',
      'en': '{0}/7 quizzes passed · {1} steps done',
    },
    'edu.labs': {'fr': 'Travaux pratiques', 'en': 'Practical labs'},
    'edu.tips': {'fr': 'Éco-gestes', 'en': 'Eco-tips'},
    'edu.glossary': {'fr': 'Glossaire', 'en': 'Glossary'},
    'edu.assistant': {'fr': 'Assistant énergie', 'en': 'Energy assistant'},
    'edu.assistant.sub': {
      'fr': 'En ligne si un serveur est configuré, sinon conseils hors-ligne.',
      'en': 'Online when a server is configured, offline advice otherwise.',
    },
    'edu.minutes': {'fr': '{0} min', 'en': '{0} min'},
    'edu.objective': {'fr': 'Objectif', 'en': 'Objective'},
    'edu.keyIdea': {'fr': 'À retenir', 'en': 'Key idea'},
    'edu.steps': {
      'fr': 'Déroulé : cochez au fur et à mesure',
      'en': 'Procedure: tick as you go',
    },
    'edu.outcomes': {'fr': 'Compétences visées', 'en': 'Learning outcomes'},
    'edu.reset': {'fr': 'Décocher toutes les étapes', 'en': 'Untick all steps'},
    'edu.quiz': {'fr': 'Quiz', 'en': 'Quiz'},
    'edu.quiz.start': {
      'fr': 'Faire le quiz ({0} questions)',
      'en': 'Take the quiz ({0} questions)',
    },
    'edu.quiz.best': {'fr': 'Meilleur score : {0}/{1}', 'en': 'Best score: {0}/{1}'},
    'edu.quiz.validate': {'fr': 'Valider mes réponses', 'en': 'Check my answers'},
    'edu.quiz.answerAll': {
      'fr': 'Répondez à toutes les questions.',
      'en': 'Answer every question.',
    },
    'edu.quiz.result': {'fr': 'Score : {0}/{1} ({2} %)', 'en': 'Score: {0}/{1} ({2}%)'},
    'edu.quiz.passed': {
      'fr': 'Réussi ! Score enregistré.',
      'en': 'Passed! Score saved.',
    },
    'edu.quiz.failed': {
      'fr': 'Pas encore : relisez la fiche et réessayez (70 % requis).',
      'en': 'Not yet: reread the sheet and try again (70% required).',
    },
    'edu.quiz.retry': {'fr': 'Recommencer', 'en': 'Try again'},
    'edu.live': {'fr': 'Données en direct', 'en': 'Live data'},
    'edu.live.kit': {'fr': 'Kit du banc', 'en': 'Bench kit'},
    'edu.live.noKit': {
      'fr': 'Ajoutez un kit (onglet Accueil) pour relier cette fiche à des mesures réelles.',
      'en': 'Add a kit (Home tab) to link this sheet to real measurements.',
    },
    'edu.meter.pulse': {'fr': 'Constante (ip)', 'en': 'Constant (ip)'},
    'edu.meter.pulseVal': {
      'fr': '{0} imp/kWh → 1 impulsion = {1} Wh',
      'en': '{0} imp/kWh → 1 pulse = {1} Wh',
    },
    'edu.meter.initial': {'fr': 'Index initial (en)', 'en': 'Initial index (en)'},
    'edu.meter.lastIndex': {'fr': 'Dernier relevé d\'index', 'en': 'Latest index reading'},
    'edu.meter.lastFrame': {'fr': 'Dernière trame horaire', 'en': 'Latest hourly frame'},
    'edu.meter.lastFrameVal': {
      'fr': '{0} kWh entre {1} h et {2} h → puissance moyenne ≈ {3} W',
      'en': '{0} kWh between {1}:00 and {2}:00 → average power ≈ {3} W',
    },
    'edu.calc.title': {'fr': 'Calculatrice E = P × t', 'en': 'Calculator E = P × t'},
    'edu.calc.power': {'fr': 'Puissance (W)', 'en': 'Power (W)'},
    'edu.calc.hours': {'fr': 'Durée (h / jour)', 'en': 'Duration (h / day)'},
    'edu.calc.result': {
      'fr': '{0} kWh/jour · {1} kWh/mois ≈ {2} FCFA/mois',
      'en': '{0} kWh/day · {1} kWh/month ≈ {2} FCFA/month',
    },
    'edu.calc.current': {
      'fr': 'Courant sous 220 V : I = P / U ≈ {0} A',
      'en': 'Current at 220 V: I = P / U ≈ {0} A',
    },
    'edu.circuits.lines': {
      'fr': 'État des lignes du banc',
      'en': 'Bench line status',
    },
    'edu.circuits.hint': {
      'fr': 'L1-L2 : ampoules · L3-L4 : prises. Toutes en parallèle sous 220 V.',
      'en': 'L1-L2: bulbs · L3-L4: sockets. All in parallel at 220 V.',
    },
    'edu.open.kit': {'fr': 'Ouvrir le kit (piloter les lignes)', 'en': 'Open the kit (control lines)'},
    'edu.open.analysis': {'fr': 'Ouvrir l\'analyse IA du kit', 'en': 'Open the kit AI analysis'},
    'edu.on': {'fr': 'ON', 'en': 'ON'},
    'edu.off': {'fr': 'OFF', 'en': 'OFF'},
    'edu.cmp.title': {'fr': 'Comparer Scénario A / B', 'en': 'Compare Scenario A / B'},
    'edu.cmp.scenario': {'fr': 'Scénario {0}', 'en': 'Scenario {0}'},
    'edu.cmp.start': {'fr': 'Démarrer', 'en': 'Start'},
    'edu.cmp.stop': {'fr': 'Terminer', 'en': 'Stop'},
    'edu.cmp.edit': {'fr': 'Ajuster', 'en': 'Adjust'},
    'edu.cmp.clear': {'fr': 'Effacer', 'en': 'Clear'},
    'edu.cmp.notStarted': {'fr': 'Non démarré', 'en': 'Not started'},
    'edu.cmp.running': {'fr': 'En cours depuis {0}', 'en': 'Running since {0}'},
    'edu.cmp.window': {'fr': '{0} → {1}', 'en': '{0} → {1}'},
    'edu.cmp.energy': {
      'fr': '{0} kWh · {1}/{2} h reçues',
      'en': '{0} kWh · {1}/{2} h received',
    },
    'edu.cmp.waiting': {
      'fr': 'En attente des trames horaires de ce créneau…',
      'en': 'Waiting for this slot\'s hourly frames…',
    },
    'edu.cmp.result.less': {
      'fr': 'B consomme {0} kWh/h de moins que A ({1} %).',
      'en': 'B uses {0} kWh/h less than A ({1}%).',
    },
    'edu.cmp.result.more': {
      'fr': 'B consomme {0} kWh/h de plus que A (+{1} %).',
      'en': 'B uses {0} kWh/h more than A (+{1}%).',
    },
    'edu.cmp.result.equal': {
      'fr': 'A et B consomment autant.',
      'en': 'A and B use the same.',
    },
    'edu.cmp.month': {
      'fr': 'Sur un mois (5 h/jour × 30 j) : {0} kWh ≈ {1} FCFA (à 79 FCFA/kWh).',
      'en': 'Over a month (5 h/day × 30 days): {0} kWh ≈ {1} FCFA (at 79 FCFA/kWh).',
    },
    'edu.cmp.incomplete': {
      'fr': 'Attention : des heures manquent, la comparaison est provisoire.',
      'en': 'Warning: some hours are missing, the comparison is provisional.',
    },
    'edu.cmp.pickStart': {'fr': 'Début du scénario', 'en': 'Scenario start'},
    'edu.cmp.pickEnd': {'fr': 'Fin du scénario', 'en': 'Scenario end'},
    'edu.iot.title': {'fr': 'Trame décodée', 'en': 'Decoded frame'},
    'edu.iot.raw': {'fr': 'Trame brute', 'en': 'Raw frame'},
    'edu.iot.date': {'fr': 'Date (JJ/MM/AA)', 'en': 'Date (DD/MM/YY)'},
    'edu.iot.slot': {'fr': 'Créneau (HH)', 'en': 'Slot (HH)'},
    'edu.iot.energy': {'fr': 'Énergie de l\'heure', 'en': 'Energy of the hour'},
    'edu.iot.count': {'fr': 'Trames stockées', 'en': 'Stored frames'},
    'edu.iot.completeness': {'fr': 'Complétude (28 j)', 'en': 'Completeness (28 d)'},
    'edu.iot.none': {
      'fr': 'Aucune trame reçue pour l\'instant. Exemple : « 27/06/26;09;0.12 ».',
      'en': 'No frame received yet. Example: "27/06/26;09;0.12".',
    },
    'edu.tip.cat.standby': {'fr': 'Veille', 'en': 'Standby'},
    'edu.tip.cat.lighting': {'fr': 'Éclairage', 'en': 'Lighting'},
    'edu.tip.cat.peak': {'fr': 'Pointe', 'en': 'Peak'},
    'edu.tip.cat.cooling': {'fr': 'Froid', 'en': 'Cooling'},
    'edu.tip.cat.habits': {'fr': 'Habitudes', 'en': 'Habits'},
    'edu.tip.cat.cost': {'fr': 'Coût', 'en': 'Cost'},

    // --- Assistant énergie ----------------------------------------------------
    'asst.title': {'fr': 'Assistant énergie', 'en': 'Energy assistant'},
    'asst.audience.learner': {'fr': 'Apprenant', 'en': 'Learner'},
    'asst.audience.owner': {'fr': 'Propriétaire', 'en': 'Owner'},
    'asst.audience.trainer': {'fr': 'Formateur', 'en': 'Trainer'},
    'asst.hint': {'fr': 'Posez votre question…', 'en': 'Ask your question…'},
    'asst.welcome': {
      'fr': 'Posez une question sur votre consommation, la facture ENEO, les '
          'économies d\'énergie ou les TP. Sans Internet, je réponds avec les '
          'conseils hors-ligne de l\'application.',
      'en': 'Ask a question about your consumption, the ENEO bill, energy '
          'savings or the labs. Without Internet, I answer with the app\'s '
          'offline advice.',
    },
    'asst.localBadge': {'fr': 'Réponse hors-ligne', 'en': 'Offline answer'},
    'asst.status.online': {
      'fr': 'En ligne · serveur EnMKit',
      'en': 'Online · EnMKit server',
    },
    'asst.status.offline': {
      'fr': 'Mode hors-ligne · conseils locaux',
      'en': 'Offline mode · local advice',
    },
    'asst.fail.notConfigured': {
      'fr': 'Serveur non configuré (Réglages → Serveur EnMKit).',
      'en': 'Server not configured (Settings → EnMKit server).',
    },
    'asst.fail.offline': {
      'fr': 'Pas de connexion au serveur : réponse hors-ligne.',
      'en': 'No connection to the server: offline answer.',
    },
    'asst.fail.unauthorized': {
      'fr': 'Clé client refusée : vérifiez-la dans les Réglages.',
      'en': 'Client key rejected: check it in Settings.',
    },
    'asst.fail.unavailable': {
      'fr': 'Assistant en ligne momentanément indisponible : réponse hors-ligne.',
      'en': 'Online assistant temporarily unavailable: offline answer.',
    },
    'asst.fail.quota': {
      'fr': "Limite de questions du jour atteinte : réponse hors-ligne. L'assistant en ligne revient demain.",
      'en': 'Daily question limit reached: offline answer. The online assistant is back tomorrow.',
    },
    'asst.quotaLeft': {
      'fr': 'Questions en ligne restantes aujourd\'hui : {0}',
      'en': 'Online questions left today: {0}',
    },
    'asst.lab': {'fr': 'Tuteur du {0}', 'en': '{0} tutor'},
    'edu.askAssistant': {
      'fr': "Demander à l'assistant sur ce TP",
      'en': 'Ask the assistant about this lab',
    },
    'asst.fail.error': {
      'fr': 'Erreur du serveur : réponse hors-ligne.',
      'en': 'Server error: offline answer.',
    },
    'asst.clear': {'fr': 'Effacer la conversation', 'en': 'Clear conversation'},
    'asst.s1': {
      'fr': 'Comment réduire ma facture ?',
      'en': 'How can I reduce my bill?',
    },
    'asst.s2': {
      'fr': 'Qu\'est-ce que la veille ?',
      'en': 'What is standby consumption?',
    },
    'asst.s3': {
      'fr': 'Combien vais-je payer ce mois ?',
      'en': 'How much will I pay this month?',
    },

    // --- Réglages : serveur EnMKit (optionnel) --------------------------------
    'settings.server': {'fr': 'Serveur EnMKit (optionnel)', 'en': 'EnMKit server (optional)'},
    'settings.server.sub': {
      'fr': 'Active l\'assistant en ligne. L\'application reste 100 % utilisable sans Internet.',
      'en': 'Enables the online assistant. The app stays fully usable without Internet.',
    },
    'settings.server.url': {'fr': 'URL de l\'API', 'en': 'API URL'},
    'settings.server.key': {'fr': 'Clé client (ck_…)', 'en': 'Client key (ck_…)'},
    'settings.server.keyHint': {
      'fr': 'Fournie à l\'activation de votre établissement',
      'en': 'Given when your organisation is activated',
    },
    'settings.server.notSet': {'fr': 'Non configuré', 'en': 'Not configured'},
    'settings.server.configured': {'fr': 'Configuré · clé {0}', 'en': 'Configured · key {0}'},
    'settings.server.edit': {'fr': 'Configurer le serveur', 'en': 'Configure the server'},
    'settings.server.test': {'fr': 'Tester la connexion', 'en': 'Test the connection'},
    'settings.server.testing': {'fr': 'Test en cours…', 'en': 'Testing…'},
    'settings.server.ok': {
      'fr': 'Connecté : {0} · {1} kit(s)',
      'en': 'Connected: {0} · {1} kit(s)',
    },
    'settings.server.remove': {'fr': 'Supprimer la configuration', 'en': 'Remove configuration'},
    'settings.server.saved': {'fr': 'Serveur enregistré', 'en': 'Server saved'},
    'settings.server.https': {
      'fr': 'Utilisez une adresse https:// (exigée par Android).',
      'en': 'Use an https:// address (required by Android).',
    },

    // --- FAQ ------------------------------------------------------------------
    // Les réponses sont des listes de points séparés par « \n ».
    'faq.title': {'fr': 'FAQ', 'en': 'FAQ'},
    'faq.home.access': {'fr': 'Accès et sécurité', 'en': 'Access and security'},
    'faq.home.access.sub': {
      'fr': "Code d'accès, empreinte et récupération",
      'en': 'Access code, fingerprint and recovery',
    },
    'faq.home.kit': {'fr': 'Kit et lignes', 'en': 'Kit and lines'},
    'faq.home.kit.sub': {
      'fr': 'Ajout, configuration, pilotage et consommation',
      'en': 'Adding, setup, control and usage',
    },
    'faq.home.qr': {'fr': 'QR Code et partage', 'en': 'QR Code and sharing'},
    'faq.home.qr.sub': {
      'fr': 'Générer, partager et importer un kit',
      'en': 'Generate, share and import a kit',
    },
    'faq.home.ai': {'fr': 'IA et apprentissage', 'en': 'AI and learning'},
    'faq.home.ai.sub': {
      'fr': 'Analyse IA, TP, quiz et assistant',
      'en': 'AI analysis, labs, quizzes and assistant',
    },
    'faq.home.trouble': {'fr': 'Dépannage', 'en': 'Troubleshooting'},
    'faq.home.trouble.sub': {
      'fr': 'Kit muet, analyse vide, assistant, support',
      'en': 'Silent kit, empty analysis, assistant, support',
    },
    'faq.common.home': {'fr': "Retour à l'accueil", 'en': 'Back to home'},
    'faq.common.needHelp': {'fr': "Besoin d'aide ?", 'en': 'Need help?'},
    'faq.common.stuck': {'fr': 'Toujours bloqué ?', 'en': 'Still stuck?'},
    'faq.common.stuck.sub': {
      'fr': 'Écrivez au support : la demande part par SMS, sans Internet.',
      'en': 'Write to support: the request is sent by SMS, no Internet needed.',
    },
    'faq.common.contact': {'fr': 'Contacter', 'en': 'Contact'},

    // Accès et sécurité
    'faq.access.hero': {
      'fr': "Protéger l'accès à l'application",
      'en': 'Protect access to the app',
    },
    'faq.access.hero.sub': {
      'fr': "Code d'accès facultatif, empreinte et questions de récupération.",
      'en': 'Optional access code, fingerprint and recovery questions.',
    },
    'faq.access.q1': {'fr': 'Faut-il créer un compte ?', 'en': 'Do I need an account?'},
    'faq.access.a1': {
      'fr': "Non. EnMKit Banc ne demande ni compte, ni e-mail, ni mot de passe.\n"
          'Vos kits et vos données restent sur ce téléphone.\n'
          "Les commandes partent par SMS : Internet n'est pas nécessaire.\n"
          "Seul un code d'accès facultatif peut protéger l'ouverture de l'application.",
      'en': 'No. EnMKit Banc needs no account, e-mail or password.\n'
          'Your kits and data stay on this phone.\n'
          'Commands are sent by SMS: no Internet is needed.\n'
          'Only an optional access code can protect the opening of the app.',
    },
    'faq.access.q2': {
      'fr': "Le code d'accès est-il obligatoire ?",
      'en': 'Is the access code mandatory?',
    },
    'faq.access.a2': {
      'fr': 'Non, il est facultatif.\n'
          "Au premier lancement, appuyez sur « Passer pour l'instant » pour ne pas en créer.\n"
          'Vous pouvez l’activer plus tard : Réglages > Sécurité > « Code de sécurité ».',
      'en': 'No, it is optional.\n'
          "On first launch, tap “Skip for now” to skip it.\n"
          'You can turn it on later: Settings > Security > “Security code”.',
    },
    'faq.access.q3': {'fr': 'Comment créer le code ?', 'en': 'How do I create the code?'},
    'faq.access.a3': {
      'fr': "Saisissez un code d'exactement 4 chiffres, puis confirmez-le.\n"
          'Choisissez deux « Questions de récupération » différentes et répondez-y.\n'
          "Si une empreinte est enregistrée sur le téléphone, l'application propose de l'activer.",
      'en': 'Enter a code of exactly 4 digits, then confirm it.\n'
          'Pick two different “Recovery questions” and answer them.\n'
          'If a fingerprint is enrolled on the phone, the app offers to enable it.',
    },
    'faq.access.q4': {
      'fr': 'Comment modifier ou désactiver le code ?',
      'en': 'How do I change or turn off the code?',
    },
    'faq.access.a4': {
      'fr': 'Ouvrez Réglages > Sécurité.\n'
          "Modifier : « Modifier le code d'accès », puis code actuel, nouveau code et confirmation.\n"
          'Désactiver : coupez « Code de sécurité ». Le code actuel est demandé.\n'
          '« Questions de récupération » permet de changer vos deux questions.',
      'en': 'Open Settings > Security.\n'
          'To change it: “Change access code”, then current code, new code and confirmation.\n'
          'To turn it off: switch off “Security code”. The current code is required.\n'
          '“Recovery questions” lets you change your two questions.',
    },
    'faq.access.q5': {'fr': "J'ai oublié mon code", 'en': 'I forgot my code'},
    'faq.access.a5': {
      'fr': "Sur l'écran du code, appuyez sur « Code oublié ? ».\n"
          'Répondez à vos deux questions. Les majuscules et les espaces en début ou en fin sont ignorés.\n'
          'Saisissez un nouveau code de 4 chiffres, puis « Réinitialiser le code ».\n'
          "Si aucune question n'est configurée, contactez le support (onglet Aide).",
      'en': 'On the code screen, tap “Forgot code?”.\n'
          'Answer your two questions. Capital letters and leading or trailing spaces are ignored.\n'
          'Enter a new 4-digit code, then tap “Reset code”.\n'
          'If no question is set, contact support (Help tab).',
    },
    'faq.access.q6': {
      'fr': "Comment déverrouiller avec l'empreinte ?",
      'en': 'How do I unlock with my fingerprint?',
    },
    'faq.access.a6': {
      'fr': "Activez d'abord le code de sécurité.\n"
          'Activez ensuite « Déverrouillage par empreinte » dans Réglages > Sécurité.\n'
          'Le code reste le moyen de secours.',
      'en': 'First turn on the security code.\n'
          'Then turn on “Fingerprint unlock” in Settings > Security.\n'
          'The code remains the fallback.',
    },
    'faq.access.q7': {
      'fr': 'Quelles autorisations accepter ?',
      'en': 'Which permissions should I allow?',
    },
    'faq.access.a7': {
      'fr': 'SMS : envoyer les commandes et lire les réponses du kit, même application fermée.\n'
          "Notifications : être prévenu à l'arrivée d'une réponse.\n"
          "Appareil photo : scanner le QR Code d'un kit.\n"
          'Empreinte : déverrouillage par empreinte (facultatif).\n'
          "Internet : uniquement pour l'Assistant énergie en ligne (facultatif).\n"
          "Sans l'autorisation SMS, le pilotage ne fonctionne pas.",
      'en': 'SMS: send commands and read the kit replies, even with the app closed.\n'
          'Notifications: be alerted when a reply arrives.\n'
          'Camera: scan the QR Code of a kit.\n'
          'Fingerprint: fingerprint unlock (optional).\n'
          'Internet: only for the online Energy assistant (optional).\n'
          'Without the SMS permission, the kits cannot be controlled.',
    },

    // Kit et lignes
    'faq.kit.hero': {
      'fr': 'Ajouter, configurer et piloter un kit',
      'en': 'Add, set up and control a kit',
    },
    'faq.kit.hero.sub': {
      'fr': 'Lignes, consommation, connexion du kit et configuration verrouillée.',
      'en': 'Lines, usage, kit connection and locked configuration.',
    },
    'faq.kit.q1': {'fr': 'Comment ajouter un kit ?', 'en': 'How do I add a kit?'},
    'faq.kit.a1': {
      'fr': 'Onglet Accueil : appuyez sur le bouton + en bas à droite.\n'
          'Dans « Nouveau kit », renseignez le « Nom du kit » et le « Numéro du kit » (numéro de sa carte SIM).\n'
          'Choisissez le « Nombre de lignes » : 4, 7 ou Personnalisé (de 1 à 7).\n'
          'Appuyez sur « Ajouter le kit ». Les lignes sont créées automatiquement.\n'
          'Pour le banc du Learning Lab, choisissez 4.',
      'en': 'Home tab: tap the + button at the bottom right.\n'
          'In “New kit”, fill in the “Kit name” and the “Kit number” (its SIM card number).\n'
          'Choose the “Number of lines”: 4, 7 or Custom (1 to 7).\n'
          'Tap “Add the kit”. The lines are created automatically.\n'
          'For the Learning Lab bench, choose 4.',
    },
    'faq.kit.q2': {'fr': 'Comment configurer le kit ?', 'en': 'How do I set up the kit?'},
    'faq.kit.a2': {
      'fr': "Ouvrez le kit, puis l'onglet Config.\n"
          'Compteur : renseignez « Impulsion par kWh » (ex. 1000) et « Consommation initiale » (kWh).\n'
          '« Numéros autorisés » : saisissez Numéro 1 et Numéro 2. Double-appuyez sur un champ pour le modifier.\n'
          'Appuyez sur « Envoyer la configuration au kit », vérifiez le récapitulatif, puis « Envoyer au kit ».',
      'en': 'Open the kit, then the Config tab.\n'
          'Meter: fill in “Pulses per kWh” (e.g. 1000) and “Initial consumption” (kWh).\n'
          '“Allowed numbers”: enter Number 1 and Number 2. Double-tap a field to edit it.\n'
          'Tap “Send configuration to the kit”, check the summary, then “Send to kit”.',
    },
    'faq.kit.q3': {
      'fr': 'Que signifie « Valider et verrouiller » ?',
      'en': 'What does “Confirm and lock” mean?',
    },
    'faq.kit.a3': {
      'fr': "Quand le kit renvoie exactement la configuration reçue, « Le retour du kit correspond » s'affiche.\n"
          'Appuyez alors sur « Valider et verrouiller », relisez, puis OK.\n'
          'La validation est définitive : relisez bien les numéros et le compteur avant.\n'
          'Ensuite, toute modification passe par les administrateurs EnMKit (onglet Aide).\n'
          "Sur l'accueil, la puce « À valider » signale un kit qui attend cette validation.",
      'en': 'When the kit sends back exactly the configuration it received, “The kit\'s reply matches” is shown.\n'
          'Then tap “Confirm and lock”, review, then OK.\n'
          'This is final: check the numbers and the meter carefully first.\n'
          'After that, any change goes through the EnMKit administrators (Help tab).\n'
          'On the home screen, the “To confirm” chip marks a kit waiting for this step.',
    },
    'faq.kit.q4': {
      'fr': 'Comment allumer ou éteindre une ligne ?',
      'en': 'How do I turn a line on or off?',
    },
    'faq.kit.a4': {
      'fr': 'Onglet Lignes : appuyez sur ON pour allumer, OFF pour éteindre.\n'
          "Le téléphone envoie un SMS au kit. Les boutons de la ligne restent bloqués pendant l'attente.\n"
          "L'état fiable est celui confirmé par le kit : touchez l'icône horloge de la ligne pour ouvrir « Confirmation de la commande ».",
      'en': 'Lines tab: tap ON to turn on, OFF to turn off.\n'
          'The phone sends an SMS to the kit. The line buttons stay locked while waiting.\n'
          'The reliable state is the one confirmed by the kit: tap the clock icon of the line to open “Command confirmation”.',
    },
    'faq.kit.q5': {
      'fr': 'Comment vérifier que le kit répond ?',
      'en': 'How do I check that the kit responds?',
    },
    'faq.kit.a5': {
      'fr': 'Onglet Lignes, carte « Connexion du kit » : appuyez sur « Tester ».\n'
          'Le statut passe à « Vérification du kit… ».\n'
          "« Kit joignable » s'affiche si le kit répond dans les 45 secondes.\n"
          'Sinon, « Kit injoignable » : vérifiez le réseau et le crédit SMS de la carte SIM du kit.',
      'en': 'Lines tab, “Kit connection” card: tap “Test”.\n'
          'The status changes to “Checking the kit…”.\n'
          '“Kit reachable” is shown if the kit replies within 45 seconds.\n'
          'Otherwise, “Kit unreachable”: check the network and SMS credit of the kit SIM card.',
    },
    'faq.kit.q6': {
      'fr': 'À quoi servent « Tout allumer » et « Tout éteindre » ?',
      'en': 'What do “Turn all on” and “Turn all off” do?',
    },
    'faq.kit.a6': {
      'fr': "Ces « Actions rapides » sont en haut de l'onglet Lignes.\n"
          "Seules les lignes qui changent d'état reçoivent une commande.\n"
          'Les SMS partent avec un court délai entre chacun.',
      'en': 'These “Quick actions” are at the top of the Lines tab.\n'
          'Only the lines that change state receive a command.\n'
          'The SMS are sent with a short delay between each one.',
    },
    'faq.kit.q7': {
      'fr': 'Comment renommer ou supprimer une ligne ?',
      'en': 'How do I rename or delete a line?',
    },
    'faq.kit.a7': {
      'fr': 'Double-appuyez sur la carte de la ligne.\n'
          'Modifiez le nom, puis appuyez sur le bouton vert pour valider.\n'
          'Le bouton rouge supprime la ligne.',
      'en': 'Double-tap the line card.\n'
          'Edit the name, then tap the green button to confirm.\n'
          'The red button deletes the line.',
    },
    'faq.kit.q8': {
      'fr': 'Comment consulter la consommation ?',
      'en': 'How do I check the usage?',
    },
    'faq.kit.a8': {
      'fr': 'Onglet Conso : appuyez sur « Vérifier votre consommation électrique ».\n'
          'À l’arrivée de « Nouvelle mesure reçue », la « Dernière mesure » est mise à jour.\n'
          "La courbe « Évolution » et l'« Historique » listent les relevés.\n"
          "Ce relevé est différent des trames horaires qui alimentent l'Analyse IA.",
      'en': 'Usage tab: tap “Check your electricity usage”.\n'
          'When “New reading received” appears, the “Last reading” is updated.\n'
          'The “Trend” chart and the “History” list the readings.\n'
          'This reading is different from the hourly frames used by the AI analysis.',
    },
    'faq.kit.q9': {'fr': 'Comment supprimer un kit ?', 'en': 'How do I delete a kit?'},
    'faq.kit.a9': {
      'fr': "Sur l'accueil, faites glisser la carte du kit vers la gauche ou la droite.\n"
          'Confirmez la suppression.\n'
          'Toutes ses données sont effacées (lignes, accusés, consommation, relevés horaires). Cette action est irréversible.',
      'en': 'On the home screen, swipe the kit card to the left or right.\n'
          'Confirm the deletion.\n'
          'All its data is erased (lines, acknowledgements, usage, hourly readings). This cannot be undone.',
    },
    'faq.kit.tip': {
      'fr': 'Astuce : sur le banc, L1 et L2 sont des ampoules, L3 et L4 des prises, toutes en parallèle sous 220 V.',
      'en': 'Tip: on the bench, L1 and L2 are bulbs, L3 and L4 are sockets, all in parallel at 220 V.',
    },

    // QR Code et partage
    'faq.qr.hero': {
      'fr': 'Partager un kit par QR Code',
      'en': 'Share a kit with a QR Code',
    },
    'faq.qr.hero.sub': {
      'fr': "Le QR Code transporte la configuration d'un kit vers un autre téléphone.",
      'en': 'The QR Code carries the configuration of a kit to another phone.',
    },
    'faq.qr.q1': {
      'fr': "Comment générer le QR Code d'un kit ?",
      'en': 'How do I generate the QR Code of a kit?',
    },
    'faq.qr.a1': {
      'fr': "Ouvrez le kit, puis l'onglet Config.\n"
          'Appuyez sur « Générer le QR Code ».\n'
          'Le QR Code contient le kit (nom, numéro, compteur), ses lignes et ses numéros autorisés.',
      'en': 'Open the kit, then the Config tab.\n'
          'Tap “Generate QR Code”.\n'
          'The QR Code holds the kit (name, number, meter), its lines and its allowed numbers.',
    },
    'faq.qr.q2': {'fr': 'Comment partager le QR Code ?', 'en': 'How do I share the QR Code?'},
    'faq.qr.a2': {
      'fr': 'Après la génération, appuyez sur « Partager le QR Code ».\n'
          "Choisissez l'application d'envoi.\n"
          'Le destinataire importe ensuite le kit avec son téléphone.',
      'en': 'Once generated, tap “Share QR Code”.\n'
          'Choose the app to send it with.\n'
          'The recipient then imports the kit with their phone.',
    },
    'faq.qr.q3': {'fr': 'Comment importer un kit ?', 'en': 'How do I import a kit?'},
    'faq.qr.a3': {
      'fr': "Onglet Accueil : appuyez sur l'icône de scanner dans l'en-tête.\n"
          "L'écran « Scanner un kit » s'ouvre : placez le QR Code dans le cadre.\n"
          'Le message « Kit « … » importé » confirme l’import.\n'
          "L'import se fait uniquement avec l'appareil photo.",
      'en': 'Home tab: tap the scanner icon in the header.\n'
          'The “Scan a kit” screen opens: place the QR Code inside the frame.\n'
          'The message “Kit “…” imported” confirms the import.\n'
          'Import only works with the camera.',
    },
    'faq.qr.q4': {
      'fr': 'Que se passe-t-il si le kit existe déjà ?',
      'en': 'What happens if the kit already exists?',
    },
    'faq.qr.a4': {
      'fr': 'Le kit qui a le même numéro est mis à jour.\n'
          'Ses lignes et ses numéros autorisés sont remplacés par ceux du QR Code.\n'
          'Vos autres kits ne changent pas.',
      'en': 'The kit with the same number is updated.\n'
          'Its lines and allowed numbers are replaced by those of the QR Code.\n'
          'Your other kits do not change.',
    },
    'faq.qr.q5': {'fr': "L'import échoue", 'en': 'The import fails'},
    'faq.qr.a5': {
      'fr': "« Import impossible » s'affiche si le QR Code n'est pas celui d'un kit EnMKit.\n"
          "Vérifiez que l'application a l'autorisation Appareil photo.\n"
          "Régénérez le QR Code depuis l'onglet Config du kit d'origine, puis réessayez.",
      'en': '“Import failed” is shown if the QR Code is not an EnMKit kit code.\n'
          'Check that the app has the Camera permission.\n'
          'Generate the QR Code again from the Config tab of the original kit, then retry.',
    },
    'faq.qr.tip': {
      'fr': 'Astuce : gardez le QR Code de chaque kit du banc pour le réinstaller vite sur un autre téléphone.',
      'en': 'Tip: keep the QR Code of each bench kit to set it up quickly on another phone.',
    },

    // IA et apprentissage
    'faq.ai.hero': {
      'fr': 'Analyse IA, module Apprendre et assistant',
      'en': 'AI analysis, Learn module and assistant',
    },
    'faq.ai.hero.sub': {
      'fr': 'Comprendre les mesures du kit, suivre les TP et poser vos questions.',
      'en': 'Understand the kit readings, follow the labs and ask your questions.',
    },
    'faq.ai.q1': {
      'fr': "D'où viennent les données de l'Analyse IA ?",
      'en': 'Where does the AI analysis data come from?',
    },
    'faq.ai.a1': {
      'fr': 'Le kit envoie sa consommation heure par heure par SMS : JJ/MM/AA;HH;KWH.\n'
          'Exemple : 27/06/26;09;0.12 signifie 0,12 kWh entre 9 h et 10 h.\n'
          "L'analyse est calculée sur le téléphone, sans Internet, sur les 28 derniers jours.\n"
          "La demande de l'onglet Conso ne remplit pas l'Analyse IA.",
      'en': 'The kit sends its usage hour by hour by SMS: DD/MM/YY;HH;KWH.\n'
          'Example: 27/06/26;09;0.12 means 0.12 kWh between 9 and 10 am.\n'
          'The analysis is computed on the phone, offline, over the last 28 days.\n'
          'The request from the Usage tab does not feed the AI analysis.',
    },
    'faq.ai.q2': {
      'fr': "Comment lire le score d'efficacité ?",
      'en': 'How do I read the efficiency score?',
    },
    'faq.ai.a2': {
      'fr': 'Le score va de 0 à 100, avec une note de A à E.\n'
          'A : 85 et plus. B : 70 à 84. C : 55 à 69. D : 40 à 54. E : moins de 40.\n'
          'La ligne « Pénalités » détaille les points retirés : veille, pointe, tendance, anomalies.\n'
          "Avec moins de 72 heures de données, l'analyse reste approximative.",
      'en': 'The score goes from 0 to 100, with a grade from A to E.\n'
          'A: 85 and above. B: 70 to 84. C: 55 to 69. D: 40 to 54. E: below 40.\n'
          'The “Penalties” line details the points removed: standby, peak, trend, anomalies.\n'
          'With less than 72 hours of data, the analysis is only approximate.',
    },
    'faq.ai.q3': {
      'fr': 'Comment est calculé le coût en FCFA ?',
      'en': 'How is the cost in FCFA computed?',
    },
    'faq.ai.a3': {
      'fr': 'Au barème progressif ENEO, par tranche mensuelle.\n'
          '0 à 110 kWh : 50 FCFA le kWh. 111 à 400 kWh : 79 FCFA.\n'
          '401 à 800 kWh : 94 FCFA. Au-delà de 800 kWh : 99 FCFA.',
      'en': 'With the progressive ENEO rates, per monthly band.\n'
          '0 to 110 kWh: 50 FCFA per kWh. 111 to 400 kWh: 79 FCFA.\n'
          '401 to 800 kWh: 94 FCFA. Above 800 kWh: 99 FCFA.',
    },
    'faq.ai.q4': {'fr': 'Comment suivre un TP ?', 'en': 'How do I follow a lab?'},
    'faq.ai.a4': {
      'fr': 'Onglet Apprendre : choisissez le kit dans « Kit du banc ».\n'
          'Touchez un TP (TP1 à TP7) dans « Travaux pratiques ».\n'
          'Cochez chaque étape du déroulé une fois réalisée. Les coches sont mémorisées.\n'
          'L’icône « Décocher toutes les étapes » remet la fiche à zéro.\n'
          'La progression est enregistrée sur le téléphone : un téléphone partagé partage aussi la progression.',
      'en': 'Learn tab: choose the kit in “Bench kit”.\n'
          'Tap a lab (TP1 to TP7) in “Practical labs”.\n'
          'Tick each step once done. Ticks are saved.\n'
          'The “Untick all steps” icon resets the sheet.\n'
          'Progress is saved on the phone: a shared phone also shares the progress.',
    },
    'faq.ai.q5': {'fr': 'Comment réussir un quiz ?', 'en': 'How do I pass a quiz?'},
    'faq.ai.a5': {
      'fr': 'Dans la fiche, appuyez sur « Faire le quiz », répondez à toutes les questions, puis « Valider mes réponses ».\n'
          'Il faut 70 % de bonnes réponses pour réussir.\n'
          'Sinon, relisez la fiche et appuyez sur « Recommencer ».\n'
          'Le meilleur score est conservé sur la fiche.',
      'en': 'In the sheet, tap “Take the quiz”, answer all the questions, then “Check my answers”.\n'
          'You need 70% correct answers to pass.\n'
          'Otherwise, reread the sheet and tap “Try again”.\n'
          'The best score is kept on the sheet.',
    },
    'faq.ai.q6': {
      'fr': 'Comment comparer les scénarios A et B ?',
      'en': 'How do I compare scenarios A and B?',
    },
    'faq.ai.a6': {
      'fr': 'La carte « Comparer Scénario A / B » est proposée dans TP4, TP5 et TP7.\n'
          'Installez la situation A, appuyez sur « Démarrer », puis « Terminer » après au moins une heure pleine.\n'
          'Faites de même pour le scénario B.\n'
          "Le résultat s'affiche à l'arrivée des trames horaires du créneau.\n"
          '« Ajuster » corrige les heures, « Effacer » supprime le scénario.',
      'en': 'The “Compare Scenario A / B” card is offered in TP4, TP5 and TP7.\n'
          'Set up situation A, tap “Start”, then “Stop” after at least one full hour.\n'
          'Do the same for scenario B.\n'
          'The result appears once the hourly frames of that time slot arrive.\n'
          '“Adjust” corrects the times, “Clear” deletes the scenario.',
    },
    'faq.ai.q7': {
      'fr': "L'assistant fonctionne-t-il sans Internet ?",
      'en': 'Does the assistant work without Internet?',
    },
    'faq.ai.a7': {
      'fr': 'Oui, en « Mode hors-ligne · conseils locaux ».\n'
          "Il répond alors avec les recommandations de l'Analyse IA, les éco-gestes et le glossaire.\n"
          'En ligne (« En ligne · serveur EnMKit »), il faut un serveur configuré et Internet.\n'
          "Ouvrez-le depuis Apprendre > Assistant énergie, ou « Poser une question à l'assistant » dans l'Analyse IA.",
      'en': 'Yes, in “Offline mode · local advice”.\n'
          'It then answers with the AI analysis recommendations, the eco-tips and the glossary.\n'
          'Online (“Online · EnMKit server”) needs a configured server and Internet.\n'
          'Open it from Learn > Energy assistant, or “Ask the assistant” in the AI analysis.',
    },
    'faq.ai.q8': {
      'fr': "Comment activer l'assistant en ligne ?",
      'en': 'How do I enable the online assistant?',
    },
    'faq.ai.a8': {
      'fr': 'Réglages > « Serveur EnMKit (optionnel) » > « Configurer le serveur ».\n'
          "« URL de l'API » : gardez l'adresse pré-remplie (https:// obligatoire).\n"
          '« Clé client (ck_…) » : saisissez la clé fournie à votre établissement.\n'
          'Appuyez sur « Enregistrer ». Le test doit afficher « Connecté : … ».\n'
          "« Tester la connexion » relance le test. L'application reste utilisable sans serveur.",
      'en': 'Settings > “EnMKit server (optional)” > “Configure the server”.\n'
          '“API URL”: keep the pre-filled address (https:// required).\n'
          '“Client key (ck_…)”: enter the key given to your institution.\n'
          'Tap “Save”. The test should show “Connected: …”.\n'
          '“Test the connection” runs the test again. The app works without a server.',
    },
    'faq.ai.q9': {
      'fr': 'Y a-t-il une limite de questions ?',
      'en': 'Is there a question limit?',
    },
    'faq.ai.a9': {
      'fr': 'Oui, par établissement et par jour.\n'
          "Le nombre restant s'affiche : « Questions en ligne restantes aujourd'hui ».\n"
          "Une fois la limite atteinte, l'assistant répond hors-ligne jusqu'au lendemain.",
      'en': 'Yes, per institution and per day.\n'
          'The remaining number is shown: “Online questions left today”.\n'
          'Once the limit is reached, the assistant answers offline until the next day.',
    },
    'faq.ai.q10': {
      'fr': "Qu'est-ce que le tuteur de TP ?",
      'en': 'What is the lab tutor?',
    },
    'faq.ai.a10': {
      'fr': "Dans une fiche TP, appuyez sur « Demander à l'assistant sur ce TP ».\n"
          "En ligne, le tuteur guide l'apprenant pas à pas, sans donner directement la réponse.\n"
          'Hors-ligne, il répond avec les conseils locaux.',
      'en': 'In a lab sheet, tap “Ask the assistant about this lab”.\n'
          'Online, the tutor guides the learner step by step, without giving the answer directly.\n'
          'Offline, it answers with local advice.',
    },
    'faq.ai.tip': {
      'fr': "Astuce : avant une séance, vérifiez que des trames horaires arrivent dans l'onglet Analyse IA du kit.",
      'en': 'Tip: before a session, check that hourly frames arrive in the AI analysis tab of the kit.',
    },

    // Dépannage
    'faq.trouble.hero': {
      'fr': 'Résoudre les problèmes courants',
      'en': 'Solve common problems',
    },
    'faq.trouble.hero.sub': {
      'fr': 'Kit qui ne répond pas, analyse vide, assistant hors-ligne, support.',
      'en': 'Kit not responding, empty analysis, offline assistant, support.',
    },
    'faq.trouble.q1': {'fr': 'Le kit ne répond pas', 'en': 'The kit does not respond'},
    'faq.trouble.a1': {
      'fr': "Vérifiez l'autorisation SMS : Paramètres Android > Applications > EnMKit Banc > Autorisations.\n"
          'Vérifiez le réseau et le crédit SMS du téléphone et du kit.\n'
          "Vérifiez le « Numéro du kit » dans l'onglet Config.\n"
          'Votre téléphone doit faire partie des « Numéros autorisés » du kit.\n'
          'Patientez : une réponse peut prendre plusieurs minutes.\n'
          'Onglet Lignes : « Tester » vérifie que le kit répond.',
      'en': 'Check the SMS permission: Android Settings > Apps > EnMKit Banc > Permissions.\n'
          'Check the network and SMS credit of the phone and of the kit.\n'
          'Check the “Kit number” in the Config tab.\n'
          'Your phone must be one of the kit “Allowed numbers”.\n'
          'Be patient: a reply can take several minutes.\n'
          'Lines tab: “Test” checks that the kit responds.',
    },
    'faq.trouble.q2': {
      'fr': '« Aucune réponse du kit » dans l\'onglet Conso',
      'en': '“No reply from the kit” in the Usage tab',
    },
    'faq.trouble.a2': {
      'fr': "Le kit n'a pas répondu dans le délai prévu.\n"
          'Vérifiez le réseau, le crédit SMS et le « Numéro du kit ».\n'
          'Réessayez avec « Vérifier votre consommation électrique ».',
      'en': 'The kit did not reply in time.\n'
          'Check the network, the SMS credit and the “Kit number”.\n'
          'Retry with “Check your electricity usage”.',
    },
    'faq.trouble.q3': {
      'fr': "Une ligne ne change pas d'état",
      'en': 'A line does not change state',
    },
    'faq.trouble.a3': {
      'fr': "Attendez la confirmation du kit : les boutons restent bloqués pendant l'envoi.\n"
          "Touchez l'icône horloge de la ligne pour voir les confirmations reçues.\n"
          'Vérifiez la « Connexion du kit » avec « Tester ».\n'
          "Si rien ne change, écrivez au support avec l'objet « Problème de commande d'une ligne ».",
      'en': 'Wait for the kit confirmation: the buttons stay locked while sending.\n'
          'Tap the clock icon of the line to see the confirmations received.\n'
          'Check the “Kit connection” with “Test”.\n'
          'If nothing changes, write to support with the topic “Problème de commande d\'une ligne” (line control problem).',
    },
    'faq.trouble.q4': {'fr': "L'Analyse IA reste vide", 'en': 'The AI analysis stays empty'},
    'faq.trouble.a4': {
      'fr': "« Pas encore de trames horaires » : aucune trame JJ/MM/AA;HH;KWH n'est arrivée.\n"
          'Les trames doivent venir du « Numéro du kit » enregistré.\n'
          "La demande de l'onglet Conso ne remplit pas l'analyse.\n"
          "Tirez l'écran vers le bas pour actualiser.",
      'en': '“No hourly frames yet”: no DD/MM/YY;HH;KWH frame has arrived.\n'
          'Frames must come from the saved “Kit number”.\n'
          'The request from the Usage tab does not feed the analysis.\n'
          'Pull the screen down to refresh.',
    },
    'faq.trouble.q5': {
      'fr': "La comparaison A / B n'aboutit pas",
      'en': 'The A / B comparison does not finish',
    },
    'faq.trouble.a5': {
      'fr': 'Chaque scénario doit être terminé (« Terminer ») et couvrir au moins une heure pleine.\n'
          'Le résultat attend les trames horaires du créneau.\n'
          'Vérifiez le kit choisi dans « Kit du banc ».',
      'en': 'Each scenario must be stopped (“Stop”) and cover at least one full hour.\n'
          'The result waits for the hourly frames of that time slot.\n'
          'Check the kit chosen in “Bench kit”.',
    },
    'faq.trouble.q6': {
      'fr': "L'assistant reste hors-ligne",
      'en': 'The assistant stays offline',
    },
    'faq.trouble.a6': {
      'fr': 'Vérifiez Réglages > « Serveur EnMKit (optionnel) » : URL et clé ck_….\n'
          'Appuyez sur « Tester la connexion ». Attendu : « Connecté : … ».\n'
          'Vérifiez le Wi-Fi ou les données mobiles.\n'
          '« Clé client refusée » : ressaisissez la clé.\n'
          '« Limite de questions du jour atteinte » : l’assistant en ligne revient le lendemain.',
      'en': 'Check Settings > “EnMKit server (optional)”: URL and ck_… key.\n'
          'Tap “Test the connection”. Expected: “Connected: …”.\n'
          'Check Wi-Fi or mobile data.\n'
          '“Client key rejected”: enter the key again.\n'
          '“Daily question limit reached”: the online assistant is back the next day.',
    },
    'faq.trouble.q7': {
      'fr': 'Comment contacter le support ?',
      'en': 'How do I contact support?',
    },
    'faq.trouble.a7': {
      'fr': 'Onglet Aide : choisissez « Votre besoin » et le « Kit concerné », ajoutez des « Précisions ».\n'
          'Appuyez sur « Envoyer au support ». La demande part par SMS.\n'
          'Vous pouvez aussi appuyer sur « Continuer sur WhatsApp ».\n'
          "Un point rouge sur l'icône Aide signale une réponse du support.\n"
          'Par écrit : contact@2metechsarl.org.',
      'en': 'Help tab: choose “Your need” and the “Kit concerned”, add “Details”.\n'
          'Tap “Send to support”. The request is sent by SMS.\n'
          'You can also tap “Continue on WhatsApp”.\n'
          'A red dot on the Help icon means support has replied.\n'
          'By e-mail: contact@2metechsarl.org.',
    },
    'faq.trouble.support': {
      'fr': 'Si le problème persiste, écrivez au support depuis l’onglet Aide en indiquant le kit concerné.',
      'en': 'If the problem persists, write to support from the Help tab and select the kit concerned.',
    },
  };
}
