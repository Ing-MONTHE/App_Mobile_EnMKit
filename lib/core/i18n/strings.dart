/// Internationalisation EnMKit — catalogue de traductions centralisé.
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
      'fr': 'Le code doit contenir au moins 4 chiffres',
      'en': 'The code must be at least 4 digits',
    },
    'access.mismatch': {
      'fr': 'Les deux codes ne correspondent pas',
      'en': 'The two codes do not match',
    },
    'access.oldWrong': {'fr': 'Ancien code incorrect', 'en': 'Old code is wrong'},
    'access.newTooShort': {
      'fr': 'Le nouveau code doit contenir au moins 4 chiffres',
      'en': 'The new code must be at least 4 digits',
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
    'forgot.newPin': {'fr': 'Nouveau code (4 chiffres min.)', 'en': 'New code (min. 4 digits)'},
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
    'relays.control': {'fr': 'Contrôle des lignes', 'en': 'Line control'},
    'relays.loading': {'fr': 'Chargement des lignes…', 'en': 'Loading lines…'},
    'relays.empty.title': {'fr': 'Aucune ligne', 'en': 'No lines'},
    'relays.empty.msg': {
      'fr': 'Ajoutez une ligne pour la piloter par SMS.',
      'en': 'Add a line to control it via SMS.',
    },
    'relays.add': {'fr': 'Ajouter une ligne', 'en': 'Add a line'},
    'relays.add.sub': {
      'fr': 'Nommez-la et choisissez son ampérage.',
      'en': 'Name it and choose its amperage.',
    },
    'relays.name': {'fr': 'Nom de la ligne', 'en': 'Line name'},
    'relays.name.hint': {'fr': 'Ex : Salon, Pompe…', 'en': 'E.g. Living room, Pump…'},
    'relays.amperage': {'fr': 'Ampérage', 'en': 'Amperage'},
    'relays.add.cta': {'fr': 'Ajouter la ligne', 'en': 'Add the line'},
    'relays.edit': {'fr': 'Modifier la ligne', 'en': 'Edit line'},
    'relays.edit.sub': {
      'fr': 'Renommez-la ou changez son ampérage.',
      'en': 'Rename it or change its amperage.',
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

    // --- Historique des accusés de réception (par ligne) ---------------------
    'relays.history': {'fr': 'Historique', 'en': 'History'},
    'relays.history.title': {
      'fr': 'Accusés de réception',
      'en': 'Acknowledgements'
    },
    'relays.history.sub': {
      'fr': 'Confirmations renvoyées par le kit pour cette ligne.',
      'en': 'Confirmations sent back by the kit for this line.'
    },
    'relays.history.empty': {
      'fr': 'Aucun accusé pour le moment.\nIls apparaîtront ici dès que le kit confirmera une commande.',
      'en': 'No acknowledgement yet.\nThey will appear here once the kit confirms a command.'
    },
    'relays.history.on': {'fr': 'Allumée', 'en': 'Turned on'},
    'relays.history.off': {'fr': 'Éteinte', 'en': 'Turned off'},
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
      'fr': 'Actualiser la consommation',
      'en': 'Refresh usage',
    },
    'cons.lastMeasure': {'fr': 'Dernière mesure', 'en': 'Last reading'},
    'cons.noMeasure': {'fr': 'Aucune mesure', 'en': 'No reading'},
    'cons.history': {'fr': 'Historique', 'en': 'History'},
    'cons.trend': {'fr': 'Évolution', 'en': 'Trend'},
    'cons.empty.title': {'fr': 'Aucune donnée', 'en': 'No data'},
    'cons.empty.msg': {
      'fr': 'Appuyez sur « Actualiser » pour interroger le kit.',
      'en': 'Tap "Refresh" to query the kit.',
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
      'fr': 'Choisissez un code à 4 chiffres minimum.',
      'en': 'Choose a code of at least 4 digits.',
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
      'fr': 'Choisissez un nouveau code à 4 chiffres minimum.',
      'en': 'Choose a new code of at least 4 digits.',
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
      'fr': 'Un code d\'accès protège l\'application. Gérez tout votre parc depuis un seul endroit.',
      'en': 'An access code protects the application. Manage your whole fleet from one place.',
    },
  };
}
