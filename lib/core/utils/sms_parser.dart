// lib/core/utils/sms_parser.dart

/// Utilitaire pour parser les messages SMS
class SmsParser {
  static Map<String, String> parseAckMessage(String ackMessage) {
    final Map<String, String> configData = {};
    final normalizedMessage = ackMessage.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    
    final patterns = {
      'n1': RegExp(r'n1:([^:]+?)(?=(?:n2|en|ip):|$)', caseSensitive: false),
      'n2': RegExp(r'n2:([^:]+?)(?=(?:n1|en|ip):|$)', caseSensitive: false),
      'en': RegExp(r'en:([^:]+?)(?=(?:n1|n2|ip):|$)', caseSensitive: false),
      'ip': RegExp(r'ip:([^:]+?)(?=(?:n1|n2|en):|$)', caseSensitive: false),
    };
    
    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(normalizedMessage);
      if (match != null) {
        final value = match.group(1) ?? '';
        if (value.isNotEmpty) configData[entry.key] = value;
      }
    }
    
    return configData;
  }
  
  static bool verifyAckMessage(String ackMessage, String expectedMessage) {
    final normalizedAck = ackMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedExpected = expectedMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    if (expectedMessage.contains(':') && expectedMessage.split(':').length > 2) {
      final expectedParts = normalizedExpected.split(':');
      for (int i = 0; i < expectedParts.length - 1; i += 2) {
        if (!normalizedAck.contains('${expectedParts[i]}:${expectedParts[i + 1]}')) {
          return false;
        }
      }
      return true;
    }
    
    return normalizedAck.contains(normalizedExpected);
  }
  
  /// Extrait une valeur de consommation (kWh) d'un SMS, ou null si absente.
  /// Gère « 12.5 kWh », « cons: 12,5 », « consommation = 12.5 ».
  static double? extractConsumption(String message) {
    final kwh = RegExp(r'(\d+(?:[\.,]\d+)?)\s*kwh', caseSensitive: false)
        .firstMatch(message);
    final match = kwh ??
        RegExp(r'cons(?:ommation)?\s*[:=]?\s*(\d+(?:[\.,]\d+)?)',
                caseSensitive: false)
            .firstMatch(message);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static String buildRelayCommand(int relayId, bool turnOn) {
    return 'r$relayId${turnOn ? "on" : "off"}';
  }
  
  static String buildConfigCommand({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) {
    // TRAME FIXE — voir SmsServiceHybrid.buildConcatenatedConfig : les quatre
    // marqueurs sont toujours présents, un champ non renseigné partant VIDE
    // (« n1:+237695864083:n2::en:110.0:ip:1000 »). Les deux constructeurs
    // doivent rester alignés, sinon la trame diffère selon le chemin d'envoi.
    final List<String> parts = [
      'n1:${firstPhone ?? ''}',
      'n2:${secondPhone ?? ''}',
      'en:${initialConsumption ?? ''}',
      'ip:${pulsation ?? ''}',
    ];
    return parts.join(':');
  }

  /// Décompose une trame de configuration TELLE QUE L'APP L'ENVOIE
  /// (« n1:+237…:n2::en:110.0:ip:1000 ») en couples clé→valeur. Une valeur peut
  /// être VIDE (champ non renseigné). Renvoie {} si la trame n'a pas cette
  /// forme — on ne devine jamais sur une chaîne inattendue.
  static Map<String, String> parseSentConfig(String frame) {
    const keys = {'n1', 'n2', 'en', 'ip'};
    final tokens = frame.trim().split(':');
    if (tokens.length < 2 || tokens.length.isOdd) return {};
    final out = <String, String>{};
    for (var i = 0; i + 1 < tokens.length; i += 2) {
      final k = tokens[i].trim().toLowerCase();
      if (!keys.contains(k)) return {};
      out[k] = tokens[i + 1].trim();
    }
    return out;
  }

  /// Vrai si [echo] — le SMS que le kit RENVOIE après une configuration —
  /// correspond à la trame [sentFrame] que l'application lui a envoyée.
  ///
  /// La comparaison est VOLONTAIREMENT tolérante, paire par paire, et NON une
  /// égalité de chaînes : le kit ré-écho avec un format variable (espaces,
  /// casse, suffixe « kWh », entier au lieu de décimal, « ; » au lieu de « : »).
  /// Une égalité stricte ne se vérifierait quasiment jamais en conditions
  /// réelles, et la confirmation ne s'afficherait pas.
  ///
  /// Les champs VIDES de la trame (« n2:: ») sont ignorés : on n'exige pas du
  /// kit qu'il ré-écho une valeur que l'utilisateur n'a pas renseignée.
  static bool configEchoMatches(String echo, String sentFrame) {
    final pairs = parseSentConfig(sentFrame);
    final checked = pairs.entries.where((e) => e.value.isNotEmpty).toList();
    // Aucune valeur exploitable => on ne peut RIEN confirmer.
    if (checked.isEmpty) return false;
    return checked.every((e) => configAckMatches(echo, e.key, e.value));
  }

  /// Vrai si l'accusé [message] du kit confirme la paire de config
  /// [key]:[expectedValue] (où [key] vaut « n1 », « n2 », « en » ou « ip »).
  ///
  /// Volontairement TOLÉRANT, car le kit ré-écho ses accusés avec un format
  /// variable (espaces, casse, « kWh » en suffixe, nombre entier au lieu de
  /// décimal…). On accepte donc une correspondance si :
  ///  • la valeur reçue est égale (après suppression des espaces, en minuscules) ;
  ///  • OU numériquement équivalente (300 == 300.0) — pour `en`/`ip` ;
  ///  • OU le même numéro (comparaison sur les 8 derniers chiffres) — pour n1/n2.
  static bool configAckMatches(String message, String key, String expectedValue) {
    final norm = message.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final k = key.toLowerCase();
    // Valeur reçue : ce qui suit « key: » jusqu'au prochain séparateur (; : ou fin).
    final m = RegExp('$k:([^;:]+)').firstMatch(norm);
    if (m == null) return false;
    // Le kit suffixe parfois la valeur par « kWh » : on l'ignore.
    final got = m.group(1)!.replaceAll('kwh', '');
    final want = expectedValue.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (got == want) return true;

    if (k == 'n1' || k == 'n2') {
      // Numéros de téléphone : on compare sur les 8 derniers chiffres (gère les
      // indicatifs/0 de tête : 699173771 ≡ +237699173771).
      final dg = got.replaceAll(RegExp(r'[^0-9]'), '');
      final dw = want.replaceAll(RegExp(r'[^0-9]'), '');
      if (dg.length >= 6 && dw.length >= 6) {
        String tail(String s) => s.length > 8 ? s.substring(s.length - 8) : s;
        return tail(dg) == tail(dw);
      }
      return false;
    }

    // en / ip : équivalence numérique (300 == 300.0, 1000 == 1000.0).
    final a = double.tryParse(got);
    final b = double.tryParse(want);
    if (a != null && b != null) return (a - b).abs() < 1e-6;
    return false;
  }
}
