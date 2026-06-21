import 'package:flutter/foundation.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsServiceHybrid {
  final KitRepository _kitRepository;

  /// Numéro du kit ciblé par ce service (mode multi-kits).
  /// Si null, on retombe sur le premier kit en base (compat. mono-kit).
  final String? kitNumber;

  SmsServiceHybrid(this._kitRepository, {this.kitNumber});

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
      // Cible : le kit explicitement associé à ce service, sinon le premier en base.
      final target = kitNumber ?? await _kitRepository.getKitNumber();

      if (target == null || target.isEmpty) {
        throw Exception("Aucun numéro de kit défini en base de données");
      }

      bool classicSuccess = false;
      try {
        debugPrint("🔵 Tentative envoi SMS classique...");
        classicSuccess = await _sendSmsClassic(target, command);
        
        if (classicSuccess) {
          debugPrint("✅ SMS envoyé avec succès (méthode classique)");
          return;
        }
      } catch (e) {
        debugPrint("⚠️ Méthode classique échouée: $e");
      }

      debugPrint("🟡 Basculement vers URL Launcher...");
      await _sendSmsUrlLauncher(target, command);
      debugPrint("✅ SMS préparé avec URL Launcher");
      
    } catch (e) {
      debugPrint("❌ Échec complet de l'envoi SMS: $e");
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
      debugPrint("Erreur méthode classique: $e");
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
      debugPrint("Erreur URL Launcher: $e");
      rethrow;
    }
  }

  Future<void> toggleRelay(RelayModel relay) async {
    if (relay.id == null) {
      throw Exception("L'identifiant de la ligne est nul");
    }

    final command = relay.isActive ? "r${relay.id}on" : "r${relay.id}off";
    await _sendCommand(command);
  }

  /// Envoie une commande d'état explicite ([on]) sans dépendre de l'état local.
  /// Utilisé par les boutons ON/OFF : on commande le kit, l'état affiché ne
  /// changera qu'à réception de l'écho SMS du kit (source de vérité).
  Future<void> commandRelay(RelayModel relay, bool on) async {
    if (relay.id == null) {
      throw Exception("L'identifiant de la ligne est nul");
    }
    await _sendCommand("r${relay.id}${on ? 'on' : 'off'}");
  }

  /// Envoie la commande pour une LIGNE par son NUMÉRO dans le kit (1..N, tel que
  /// câblé/configuré DANS le kit) — et NON l'id base de données. Le kit n'accepte
  /// que des lignes 1 à 7 (« r1on »…« r7on ») : on ne doit jamais envoyer un
  /// « r10on » bâti sur un id base. C'est la couche appelante qui fournit le bon
  /// numéro de ligne (position de la ligne dans le kit).
  Future<void> commandLine(int lineNumber, bool on) async {
    await _sendCommand("r$lineNumber${on ? 'on' : 'off'}");
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

  /// Construit le message de configuration concaténé (n1/n2/en/ip) tel qu'il
  /// sera envoyé au kit — SANS l'envoyer. Sert à l'aperçu avant validation.
  ///
  /// IMPORTANT : les paires sont séparées par « : » (PAS « ; »), conformément à
  /// la syntaxe attendue par le kit :
  ///   n1:+237…:n2:+237…:en:10.8:ip:1000
  /// (Un mauvais séparateur empêchait le kit de parser la config — et donc de
  /// renvoyer son accusé.)
  String buildConcatenatedConfig({
    String? firstPhone,
    String? secondPhone,
    required double initialConsumption,
    required int pulsation,
  }) {
    final parts = <String>[];
    if (firstPhone != null && firstPhone.isNotEmpty) {
      parts.add("n1:${formatPhoneNumber(firstPhone)}");
    }
    if (secondPhone != null && secondPhone.isNotEmpty) {
      parts.add("n2:${formatPhoneNumber(secondPhone)}");
    }
    parts.add("en:$initialConsumption");
    parts.add("ip:$pulsation");
    return parts.join(":");
  }

  Future<String> sendConcatenatedSystemConfig({
    String? firstPhone,
    String? secondPhone,
    required double initialConsumption,
    required int pulsation,
  }) async {
    final message = buildConcatenatedConfig(
      firstPhone: firstPhone,
      secondPhone: secondPhone,
      initialConsumption: initialConsumption,
      pulsation: pulsation,
    );
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
    debugPrint('=== PARSE ACK MESSAGE DEBUG ===');
    debugPrint('Message original: "$ackMessage"');
    debugPrint('Longueur: ${ackMessage.length}');
    debugPrint('Contient n1: ${ackMessage.toLowerCase().contains('n1:')}');
    debugPrint('Contient n2: ${ackMessage.toLowerCase().contains('n2:')}');
    debugPrint('Contient en: ${ackMessage.toLowerCase().contains('en:')}');
    debugPrint('Contient ip: ${ackMessage.toLowerCase().contains('ip:')}');
    
    // Normaliser le message (supprimer espaces et convertir en minuscules)
    final normalizedMessage = ackMessage.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    debugPrint('Message normalisé: "$normalizedMessage"');
    
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
            debugPrint('✓ n1 trouvé: $value');
            break;
          case 'n2':
            configData['Numéro 2'] = value;
            debugPrint('✓ n2 trouvé: $value');
            break;
          case 'en':
            configData['Consommation initiale'] = '$value kWh';
            debugPrint('✓ en trouvé: $value');
            break;
          case 'ip':
            configData['Pulsations'] = value;
            debugPrint('✓ ip trouvé: $value');
            break;
        }
      } else {
        debugPrint('✗ $key non trouvé');
      }
    }
    
    debugPrint('Résultat du parsing: $configData');
    debugPrint('=== FIN PARSE ACK DEBUG ===');
    
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
