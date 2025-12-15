import 'dart:async';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/viewmodels/consumption_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:readsms/readsms.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsListenerViewModel extends ChangeNotifier {

  final repo_consumption=ConsumptionRepository(DBService());
  final String? kitNumber;
  final ConsumptionViewModel? consumptionVM; // Injecté pour mise à jour immédiate UI
  late String? trustedSender; // 🔧 Numéro autorisé 
  SmsListenerViewModel({required this.kitNumber, this.consumptionVM}) {
    trustedSender = _normalizeNumber(kitNumber);
    _initSmsListener();
  }
  final plugin = Readsms();
  String lastSms = "Aucun Donnée";
  final StreamController<String> _trustedSmsController = StreamController<String>.broadcast();

  /// Flux des SMS reçus provenant uniquement du kit (numéro de confiance)
  Stream<String> get trustedSms$ => _trustedSmsController.stream;

  // Fenêtre d'acceptation de réponse consommation
  bool _awaitingConsumption = false;
  DateTime? _awaitConsumptionUntil;
  void armConsumptionWindow({Duration window = const Duration(minutes: 1)}) {
    _awaitingConsumption = true;
    _awaitConsumptionUntil = DateTime.now().add(window);
  }


  Future<void> _initSmsListener() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      plugin.read();

      plugin.smsStream.listen((event) {
        final normalizedSender = _normalizeNumber(event.sender);
        final normalizedTrusted = trustedSender;

        final isFromTrusted = normalizedTrusted == null
            ? true
            : _numbersMatch(normalizedSender, normalizedTrusted);

        if (isFromTrusted) {
          final body = event.body ?? "";
          // Ne pas écraser lastSms par défaut; confier l'affichage à _processTrustedSms
          _trustedSmsController.add(body);
          _processTrustedSms(body);
        } else {
          lastSms = "❌ SMS rejeté : ${event.body} (de: ${event.sender})";
        }
        notifyListeners(); // 🔔 Met à jour la Vue
      });
    } else {
      lastSms = "❌ Permission SMS refusée";
      notifyListeners();
    }
  }

  String? _normalizeNumber(String? number) {
    if (number == null) return null;
    // Garder uniquement les chiffres
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    // Supprimer un 00 initial (format international)
    final withoutIdd = digits.startsWith('00') ? digits.substring(2) : digits;
    // Supprimer un 0 local de tête si un indicatif pays est présent
    return withoutIdd;
  }

  bool _numbersMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    // Compare sur les 8 derniers chiffres pour gérer indicatifs différents
    final aTail = a.length > 8 ? a.substring(a.length - 8) : a;
    final bTail = b.length > 8 ? b.substring(b.length - 8) : b;
    return aTail == bTail;
  }

  void _processTrustedSms(String message) {
    // 👉 Ne traiter la consommation QUE si on attend une réponse cons ET que le SMS ressemble à une réponse de conso
    try {
      final now = DateTime.now();
      final windowActive = _awaitingConsumption && (_awaitConsumptionUntil == null || now.isBefore(_awaitConsumptionUntil!));
      // Accepte aussi une consommation si elle arrive peu après la fenêtre (grâce à une marge)
      final graceWindowActive = _awaitConsumptionUntil != null && now.isBefore(_awaitConsumptionUntil!.add(const Duration(minutes: 1)));
      if ((windowActive || graceWindowActive) && _looksLikeConsumptionResponse(message)) {
        // 1) Cherche un motif "nombre + kWh"
        final kwhRegex = RegExp(r'(\d+(?:[\.,]\d+)?)\s*kWh', caseSensitive: false);
        RegExpMatch? match = kwhRegex.firstMatch(message);

        String? numericText;
        if (match != null) {
          numericText = match.group(1);
        } else {
          // 2) Sinon, essaye de récupérer un nombre après des mots-clés conso
          final genericAfterConsRegex = RegExp(
            r'(cons(?:ommation)?\s*[:=]?\s*)(\d+(?:[\.,]\d+)?)',
            caseSensitive: false,
          );
          match = genericAfterConsRegex.firstMatch(message);
          if (match != null) {
            numericText = match.group(2);
          }
        }

        if (numericText != null) {
          final parsed = double.tryParse(numericText.replaceAll(',', '.'));
          if (parsed != null) {
            final model = ConsumptionModel(kwh: parsed, timestamp: DateTime.now());
            repo_consumption.addConsumption(model);
            consumptionVM?.addConsumption(model);
            lastSms = "$parsed kWh";
            // Considère la première réponse comme consumée et ferme la fenêtre
            _awaitingConsumption = false;
            _awaitConsumptionUntil = null;
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

  }

  /// Heuristique simple pour différencier une réponse de consommation d'un ACK
  bool _looksLikeConsumptionResponse(String message) {
    final lower = message.toLowerCase();
    return lower.contains('kwh') ||
        lower.contains('cons:') ||
        lower.contains('cons=') ||
        lower.startsWith('cons ') ||
        lower.contains('consommation') ||
        lower.startsWith('conso ');
  }

  /// Vérifie si un message est un accusé de réception avec les nouveaux formats
  bool _isAckMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('n1:') ||  // accusé numéro 1
           lower.contains('n2:') ||  // accusé numéro 2
           lower.contains('en:') ||  // accusé consommation initiale
           lower.contains('ip:') ||  // accusé pulsation
           lower.contains('Fin_config') ||   // accusé apply_config
           // Anciens formats pour compatibilité
           lower.contains('num:') ||
           lower.contains('cons_initial:') ||
           lower.contains('puls:') ||
           lower.contains('Fin_config');
  }

  /// Attend un accusé contenant [expectedSubstring]. Retourne true si reçu avant [timeout].
  Future<bool> waitForAckContains(String expectedSubstring, {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final completer = Completer<bool>();
      late StreamSubscription sub;
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          sub.cancel();
          completer.complete(false);
        }
      });
      sub = trustedSms$.listen((msg) {
        if (msg.toLowerCase().contains(expectedSubstring.toLowerCase())) {
          if (!completer.isCompleted) {
            timer.cancel();
            sub.cancel();
            completer.complete(true);
          }
        }
      });
      return completer.future;
    } catch (_) {
      return false;
    }
  }

  /// Attend une liste d'acks dans l'ordre. Arrête au premier échec.
  Future<bool> waitForAcksInOrder(List<String> expectedSubstrings, {Duration perAckTimeout = const Duration(seconds: 30)}) async {
    for (final expected in expectedSubstrings) {
      final ok = await waitForAckContains(expected, timeout: perAckTimeout);
      if (!ok) return false;
    }
    return true;
  }

  /// Attend que tous les ACKs attendus soient reçus, dans n'importe quel ordre,
  /// avant la fin de [totalTimeout]. Retourne true si tous reçus.
  Future<bool> waitForAllAcks(Set<String> expectedSubstrings, {Duration totalTimeout = const Duration(minutes: 5)}) async {
    if (expectedSubstrings.isEmpty) return true;
    final remaining = expectedSubstrings.map((e) => e.toLowerCase()).toSet();
    final completer = Completer<bool>();
    late StreamSubscription sub;
    final timer = Timer(totalTimeout, () {
      if (!completer.isCompleted) {
        sub.cancel();
        completer.complete(false);
      }
    });
    sub = trustedSms$.listen((msg) {
      final lower = msg.toLowerCase();
      remaining.removeWhere((needle) => lower.contains(needle));
      if (remaining.isEmpty && !completer.isCompleted) {
        timer.cancel();
        sub.cancel();
        completer.complete(true);
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    _trustedSmsController.close();
    super.dispose();
  }
}


// import 'package:flutter/foundation.dart';
// import 'package:readsms/readsms.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SmsListenerViewModel extends ChangeNotifier {
//   final Readsms _plugin = Readsms();
//   String lastSms = "Aucune Donnée";

//   /// Numéro du kit à écouter
//   String trustedSender;

//   SmsListenerViewModel({required this.trustedSender}) {
//     _initSmsListener();
//   }

//   /// Initialisation de l'écoute des SMS
//   Future<void> _initSmsListener() async {
//     var status = await Permission.sms.request();
//     if (status.isGranted) {
//       _plugin.read();
//       _plugin.smsStream.listen((event) {
//         if (event.sender == trustedSender) {
//           lastSms = "✅ SMS autorisé : ${event.body}";
//           _processTrustedSms(event.body ?? "");
//         } else {
//           lastSms = "❌ SMS rejeté : ${event.body} (de: ${event.sender})";
//         }
//         notifyListeners();
//       });
//     } else {
//       lastSms = "❌ Permission SMS refusée";
//       notifyListeners();
//     }
//   }

//   /// Logique métier pour un SMS autorisé
//   void _processTrustedSms(String message) {
//     if (_isAck(message)) {
//       debugPrint("📩 Accusé de réception reçu !");
//     }

//     final consumption = _extractConsumption(message);
//     if (consumption != null) {
//       debugPrint("⚡ Consommation détectée : $consumption kWh");
//     }

//     if (_isRelayCommand(message)) {
//       debugPrint("🔌 Commande relais détectée : $message");
//     }
//   }

//   /// Vérifie si le message contient un accusé de réception
//   bool _isAck(String message) {
//     final ackKeywords = ['ok', 'reçu', 'received'];
//     return ackKeywords.any((k) => message.toLowerCase().contains(k));
//   }

//   /// Extrait la consommation si présente (ex: "Consommation: 12.5 kWh")
//   double? _extractConsumption(String message) {
//     try {
//       final regex = RegExp(r'(\d+(\.\d+)?)\s*kWh');
//       final match = regex.firstMatch(message);
//       if (match != null) return double.tryParse(match.group(1)!);
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   /// Vérifie si le message contient une commande de relais
//   bool _isRelayCommand(String message) {
//     return message.contains("ON") || message.contains("OFF");
//   }
// }
