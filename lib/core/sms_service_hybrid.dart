import 'package:enmkit/models/relay_model.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsServiceHybrid {
  final KitRepository _kitRepository;

  SmsServiceHybrid(this._kitRepository);

  String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.startsWith('+237')) {
      return cleanNumber;
    }
    
    if (cleanNumber.startsWith('237')) {
      return '+$cleanNumber';
    }
    
    if (cleanNumber.startsWith('0')) {
      return '+237${cleanNumber.substring(1)}';
    }
    
    if (cleanNumber.length >= 6 && cleanNumber.length <= 9) {
      return '+237$cleanNumber';
    }
    
    return cleanNumber;
  }

  Future<void> _sendCommand(String command) async {
    try {
      final kitNumber = await _kitRepository.getKitNumber();

      if (kitNumber == null || kitNumber.isEmpty) {
        throw Exception("Aucun numéro de kit défini en base de données");
      }

      bool classicSuccess = false;
      try {
        print("🔵 Tentative envoi SMS classique...");
        classicSuccess = await _sendSmsClassic(kitNumber, command);
        
        if (classicSuccess) {
          print("✅ SMS envoyé avec succès (méthode classique)");
          return;
        }
      } catch (e) {
        print("⚠️ Méthode classique échouée: $e");
      }

      print("🟡 Basculement vers URL Launcher...");
      await _sendSmsUrlLauncher(kitNumber, command);
      print("✅ SMS préparé avec URL Launcher");
      
    } catch (e) {
      print("❌ Échec complet de l'envoi SMS: $e");
      rethrow;
    }
  }

  Future<bool> _sendSmsClassic(String phoneNumber, String message) async {
    try {
      final smsSender = SmsSender();
      
      final hasPermission = await smsSender.checkSmsPermission();
      if (!hasPermission) {
        await smsSender.requestSmsPermission();
      }

      final success = await smsSender.sendSms(
        phoneNumber: phoneNumber,
        message: message,
        simSlot: 0,
      );

      return success;
    } catch (e) {
      print("Erreur méthode classique: $e");
      return false;
    }
  }

  Future<void> _sendSmsUrlLauncher(String phoneNumber, String message) async {
    try {
      String cleanNumber = phoneNumber.replaceAll('+', '');
      String encodedMessage = Uri.encodeComponent(message);
      final Uri smsUri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception("Impossible d'ouvrir l'application SMS");
      }
    } catch (e) {
      print("Erreur URL Launcher: $e");
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

  Future<void> requestConsumption() async {
    await _sendCommand("cons");
  }

  Future<void> setFirstPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n1:$formattedPhone");
  }

  Future<void> setSecondPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n2:$formattedPhone");
  }

  Future<void> setInitialConsumption(double consInitial) async {
    await _sendCommand("en:$consInitial");
  }

  Future<void> setPulseCount(int pulseCount) async {
    await _sendCommand("ip:$pulseCount");
  }

  Future<String> sendConcatenatedSystemConfig({
    String? firstPhone,
    String? secondPhone,
    required double initialConsumption,
    required int pulsation,
  }) async {
    String message = "";
    
    if (firstPhone != null && firstPhone.isNotEmpty) {
      final formatted = formatPhoneNumber(firstPhone);
      message += "n1:$formatted;";
    }
    
    if (secondPhone != null && secondPhone.isNotEmpty) {
      final formatted = formatPhoneNumber(secondPhone);
      message += "n2:$formatted;";
    }
    
    message += "en:$initialConsumption;";
    message += "ip:$pulsation";
    
    await _sendCommand(message);
    return message;
  }

  Future<void> sendMultipleCommands(List<String> commands) async {
    for (final command in commands) {
      await _sendCommand(command);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// ============================================================================
  /// MÉTHODES SUPPLÉMENTAIRES (Compatibilité avec SmsService)
  /// ============================================================================

  /// Applique la configuration finale
  Future<void> applyConfiguration() async {
    await _sendCommand("Fin_config");
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
            print('✓ n1 trouvé: $value');
            break;
          case 'n2':
            configData['Numéro 2'] = value;
            print('✓ n2 trouvé: $value');
            break;
          case 'en':
            configData['Consommation initiale'] = '$value kWh';
            print('✓ en trouvé: $value');
            break;
          case 'ip':
            configData['Pulsations'] = value;
            print('✓ ip trouvé: $value');
            break;
        }
      } else {
        print('✗ $key non trouvé');
      }
    }
    
    print('Résultat du parsing: $configData');
    print('=== FIN PARSE ACK DEBUG ===');
    
    return configData;
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
}
