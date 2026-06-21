class DefaultData {
  static const adminPhoneNumber = '666666666';
  static const adminPassword = '1234';

  static const defaultRelays = [
    {'name': 'Ligne 1', 'isActive': 0, 'amperage': 4},
    {'name': 'Ligne 2', 'isActive': 0, 'amperage': 4},
    {'name': 'Ligne 3', 'isActive': 0, 'amperage': 4},
  ];

  /// Nombre maximum de lignes par kit.
  static const int maxRelaysPerKit = 7;

  /// Nombre de lignes créées par défaut à la création d'un kit.
  static const int defaultLineCount = 4;

  /// Ampérage par défaut d'une ligne (l'info n'est plus saisie côté utilisateur).
  static const int defaultAmperage = 4;
}
