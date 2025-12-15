import 'package:enmkit/models/relay_model.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:enmkit/repositories/kit_repository.dart';

class SmsService {
  final KitRepository _kitRepository;

  SmsService(this._kitRepository);

  /// Formate automatiquement un numéro de téléphone en ajoutant l'indicatif pays +237 si manquant
  String formatPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro (supprimer espaces, tirets, etc.)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si le numéro commence déjà par +237, le retourner tel quel
    if (cleanNumber.startsWith('+237')) {
      return cleanNumber;
    }
    
    // Si le numéro commence par 237, ajouter le +
    if (cleanNumber.startsWith('237')) {
      return '+$cleanNumber';
    }
    
    // Si le numéro commence par 0, le remplacer par +237
    if (cleanNumber.startsWith('0')) {
      return '+237${cleanNumber.substring(1)}';
    }
    
    // Si le numéro est un numéro local (6, 7, 8, 9 chiffres), ajouter +237
    if (cleanNumber.length >= 6 && cleanNumber.length <= 9) {
      return '+237$cleanNumber';
    }
    
    // Sinon, retourner le numéro tel quel
    return cleanNumber;
  }

  /// Méthode générique pour envoyer un SMS
  Future<void> _sendCommand(String command) async {
    try {
      // 1. Récupère le numéro du kit depuis SQLite
      final kitNumber = await _kitRepository.getKitNumber();

      if (kitNumber == null || kitNumber.isEmpty) {
        throw Exception("Aucun numéro de kit défini en base de données");
      }

      // 2. Envoie le SMS
      final smsSender = SmsSender();
      final hasPermission = await smsSender.checkSmsPermission();

      if (!hasPermission) {
        await smsSender.requestSmsPermission();
      }

      final success = await smsSender.sendSms(
        phoneNumber: kitNumber,
        message: command,
        simSlot: 0, // Spécifie le slot SIM si nécessaire
      );

      if (!success) {
        throw Exception("Échec de l'envoi du SMS");
      }
    } catch (e) {
      rethrow;
    }
  }

Future<void> toggleRelay(RelayModel relay) async {
  if (relay.id == null) {
    throw Exception("L'identifiant du relais est nul");
  }

  final command = relay.isActive ? "r${relay.id}on" : "r${relay.id}off";
  await _sendCommand(command);
}


  /// Consommation actuelle
  Future<void> requestConsumption() async {
    await _sendCommand("cons");
  }

  /// Définir le premier numéro autorisé (n1:+237678123456)
  Future<void> setFirstPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n1:$formattedPhone");
  }

  /// Définir le second numéro autorisé (n2:+237698435687)
  Future<void> setSecondPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n2:$formattedPhone");
  }

  /// Définir consommation initiale (en:300.0)
  Future<void> setInitialConsumption(double consInitial) async {
    await _sendCommand("en:$consInitial");
  }

  /// Définir le nombre de pulsations (ip:200)
  Future<void> setPulsation(int puls) async {
    await _sendCommand("ip:$puls");
  }

  /// Demander au kit d'appliquer/committer la configuration reçue (ok)
  Future<void> applyConfiguration() async {
    await _sendCommand("Fin_config");
  }

  /// Envoie la configuration système complète en un seul message concaténé
  Future<String> sendConcatenatedSystemConfig({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) async {
    // Construction du message concaténé au format: n1:+237xxx:n2:+237xxx:en:xx.x:ip:xxxx
    List<String> parts = [];
    
    if (firstPhone != null && firstPhone.isNotEmpty) {
      final formattedPhone = formatPhoneNumber(firstPhone);
      parts.add("n1:$formattedPhone");
    }
    
    if (secondPhone != null && secondPhone.isNotEmpty) {
      final formattedPhone = formatPhoneNumber(secondPhone);
      parts.add("n2:$formattedPhone");
    }
    
    if (initialConsumption != null) {
      parts.add("en:$initialConsumption");
    }
    
    if (pulsation != null) {
      parts.add("ip:$pulsation");
    }
    
    final concatenatedMessage = parts.join(':');
    await _sendCommand(concatenatedMessage);
    return concatenatedMessage;
  }

  /// Méthode pour maintenir la compatibilité (deprecated)
  @Deprecated('Use setFirstPhoneNumber or setSecondPhoneNumber instead')
  Future<void> setPhoneNumber(String phone) async {
    await setFirstPhoneNumber(phone);
  }

  /// Génère les messages attendus pour la vérification stricte
  Map<String, String> generateExpectedMessages({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) {
    final Map<String, String> expectedMessages = {};
    
    if (firstPhone != null) {
      final formattedPhone = formatPhoneNumber(firstPhone);
      expectedMessages['n1'] = "n1:$formattedPhone";
    }
    
    if (secondPhone != null) {
      final formattedPhone = formatPhoneNumber(secondPhone);
      expectedMessages['n2'] = "n2:$formattedPhone";
    }
    
    if (initialConsumption != null) {
      expectedMessages['en'] = "en:$initialConsumption";
    }
    
    if (pulsation != null) {
      expectedMessages['ip'] = "ip:$pulsation";
    }
    
    return expectedMessages;
  }

  /// Vérifie si un message d'accusé correspond exactement au message envoyé
  bool verifyAckMessage(String ackMessage, String expectedMessage) {
    // Normaliser les messages pour la comparaison (supprimer espaces, casse)
    final normalizedAck = ackMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedExpected = expectedMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    // Pour les messages concaténés, vérifier que l'ACK contient toutes les parties
    if (expectedMessage.contains(':') && expectedMessage.split(':').length > 2) {
      // Message concaténé - vérifier chaque partie
      final expectedParts = normalizedExpected.split(':');
      for (int i = 0; i < expectedParts.length - 1; i += 2) {
        final key = expectedParts[i];
        final value = expectedParts[i + 1];
        final expectedPart = '$key:$value';
        if (!normalizedAck.contains(expectedPart)) {
          return false;
        }
      }
      return true;
    } else {
      // Message simple - vérification normale
      return normalizedAck.contains(normalizedExpected);
    }
  }

  /// Parse l'accusé de réception pour extraire les informations de configuration
  Map<String, String> parseAckMessage(String ackMessage) {
    final Map<String, String> configData = {};
    
    // Debug détaillé
    print('=== PARSE ACK MESSAGE DEBUG ===');
    print('Message original: "$ackMessage"');
    print('Longueur: ${ackMessage.length}');
    print('Contient n1: ${ackMessage.toLowerCase().contains('n1:')}');
    print('Contient n2: ${ackMessage.toLowerCase().contains('n2:')}');
    print('Contient en: ${ackMessage.toLowerCase().contains('en:')}');
    print('Contient ip: ${ackMessage.toLowerCase().contains('ip:')}');
    
    // Normaliser le message (supprimer espaces et convertir en minuscules)
    final normalizedMessage = ackMessage.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    print('Message normalisé: "$normalizedMessage"');
    
    // Méthode plus robuste : chercher chaque pattern individuellement
    final patterns = {
      'n1': RegExp(r'n1:([^:]+?)(?=(?:n2|en|ip):|$)', caseSensitive: false),
      'n2': RegExp(r'n2:([^:]+?)(?=(?:n1|en|ip):|$)', caseSensitive: false),
      'en': RegExp(r'en:([^:]+?)(?=(?:n1|n2|ip):|$)', caseSensitive: false),
      'ip': RegExp(r'ip:([^:]+?)(?=(?:n1|n2|en):|$)', caseSensitive: false),
    };
    
    for (final entry in patterns.entries) {
      final key = entry.key;
      final regex = entry.value;
      final match = regex.firstMatch(normalizedMessage);
      
      if (match != null) {
        final value = match.group(1) ?? '';
        
        switch (key) {
          case 'n1':
            configData['Numéro 1'] = value;
            break;
          case 'n2':
            configData['Numéro 2'] = value;
            break;
          case 'en':
            configData['Consommation initiale'] = '$value kWh';
            break;
          case 'ip':
            configData['Pulsation'] = value;
            break;
        }
      }
    }
    
    // Si la méthode regex échoue, essayer une approche par division simple
    if (configData.isEmpty) {
      // Méthode alternative : recherche directe des patterns
      final keyValuePairs = <String, String>{};
      
      // Chercher n1:
      RegExp n1Pattern = RegExp(r'n1:([^:]*?)(?=n2:|en:|ip:|$)', caseSensitive: false);
      final n1Match = n1Pattern.firstMatch(normalizedMessage);
      if (n1Match != null) keyValuePairs['n1'] = n1Match.group(1) ?? '';
      
      // Chercher n2:
      RegExp n2Pattern = RegExp(r'n2:([^:]*?)(?=n1:|en:|ip:|$)', caseSensitive: false);
      final n2Match = n2Pattern.firstMatch(normalizedMessage);
      if (n2Match != null) keyValuePairs['n2'] = n2Match.group(1) ?? '';
      
      // Chercher en:
      RegExp enPattern = RegExp(r'en:([^:]*?)(?=n1:|n2:|ip:|$)', caseSensitive: false);
      final enMatch = enPattern.firstMatch(normalizedMessage);
      if (enMatch != null) keyValuePairs['en'] = enMatch.group(1) ?? '';
      
      // Chercher ip:
      RegExp ipPattern = RegExp(r'ip:([^:]*?)(?=n1:|n2:|en:|$)', caseSensitive: false);
      final ipMatch = ipPattern.firstMatch(normalizedMessage);
      if (ipMatch != null) keyValuePairs['ip'] = ipMatch.group(1) ?? '';
      
      // Convertir en format d'affichage
      for (final entry in keyValuePairs.entries) {
        final key = entry.key;
        final value = entry.value;
        
        switch (key) {
          case 'n1':
            if (value.isNotEmpty) configData['Numéro 1'] = value;
            break;
          case 'n2':
            if (value.isNotEmpty) configData['Numéro 2'] = value;
            break;
          case 'en':
            if (value.isNotEmpty) configData['Consommation initiale'] = '$value kWh';
            break;
          case 'ip':
            if (value.isNotEmpty) configData['Pulsation'] = value;
            break;
        }
      }
    }
    
    // Si toujours vide, essayer la méthode de division par paires
    if (configData.isEmpty) {
      final parts = normalizedMessage.split(':');
      for (int i = 0; i < parts.length - 1; i += 2) {
        if (i + 1 < parts.length) {
          final key = parts[i].toLowerCase();
          final value = parts[i + 1];
          
          // Nettoyer la valeur si elle contient d'autres clés
          String cleanValue = value;
          for (final nextKey in ['n1', 'n2', 'en', 'ip']) {
            if (cleanValue.contains(nextKey)) {
              cleanValue = cleanValue.substring(0, cleanValue.indexOf(nextKey));
              break;
            }
          }
          
          switch (key) {
            case 'n1':
              if (cleanValue.isNotEmpty) configData['Numéro 1'] = cleanValue;
              break;
            case 'n2':
              if (cleanValue.isNotEmpty) configData['Numéro 2'] = cleanValue;
              break;
            case 'en':
              if (cleanValue.isNotEmpty) configData['Consommation initiale'] = '$cleanValue kWh';
              break;
            case 'ip':
              if (cleanValue.isNotEmpty) configData['Pulsation'] = cleanValue;
              break;
          }
        }
      }
    }
    
    // Si toujours aucune donnée, essayer une méthode manuelle très simple
    if (configData.isEmpty) {
      print('Tentative de parsing manuel...');
      configData.addAll(_parseManually(ackMessage));
    }
    
    print('Données finales extraites: $configData');
    print('================================');
    
    return configData;
  }

  /// Méthode de parsing manuel très simple
  Map<String, String> _parseManually(String message) {
    final Map<String, String> result = {};
    final lowerMessage = message.toLowerCase();
    
    // Chercher chaque pattern manuellement
    final patterns = ['n1:', 'n2:', 'en:', 'ip:'];
    
    for (final pattern in patterns) {
      final startIndex = lowerMessage.indexOf(pattern);
      if (startIndex != -1) {
        final valueStart = startIndex + pattern.length;
        String value = '';
        
        // Extraire la valeur jusqu'au prochain pattern ou fin de chaîne
        int endIndex = message.length;
        for (final nextPattern in patterns) {
          if (nextPattern != pattern) {
            final nextIndex = lowerMessage.indexOf(nextPattern, valueStart);
            if (nextIndex != -1 && nextIndex < endIndex) {
              endIndex = nextIndex;
            }
          }
        }
        
        if (valueStart < endIndex) {
          value = message.substring(valueStart, endIndex).trim();
          
          // Supprimer les caractères parasites à la fin
          value = value.replaceAll(RegExp(r'[^+\d.\-a-zA-Z]$'), '');
          
          if (value.isNotEmpty) {
            switch (pattern) {
              case 'n1:':
                result['Numéro 1'] = value;
                break;
              case 'n2:':
                result['Numéro 2'] = value;
                break;
              case 'en:':
                result['Consommation initiale'] = '$value kWh';
                break;
              case 'ip:':
                result['Pulsation'] = value;
                break;
            }
            print('Trouvé $pattern -> "$value"');
          }
        }
      }
    }
    
    return result;
  }

}
