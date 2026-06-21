import 'dart:async';

import 'package:flutter/services.dart';

/// Pont vers le code natif Android pour la réception des SMS en arrière-plan.
///
/// Côté natif, un BroadcastReceiver capte les SMS entrants (même app fermée),
/// les filtre sur les numéros de kits connus, et les empile dans une file
/// persistante (SharedPreferences). Côté Dart, on draine cette file à
/// l'ouverture et à chaque reprise de l'app.
class BackgroundSmsBridge {
  static const MethodChannel _method =
      MethodChannel('enmkit/sms_background');
  static const EventChannel _events =
      EventChannel('enmkit/sms_background_events');

  /// Émet un signal à chaque nouveau SMS de kit reçu pendant que l'app vit.
  Stream<void> get onNewSms =>
      _events.receiveBroadcastStream().map((_) {});

  /// Transmet au natif la liste des numéros de kits à surveiller (filtrage).
  Future<void> setKitNumbers(List<String> numbers) async {
    await _method.invokeMethod('setKitNumbers', {'numbers': numbers});
  }

  /// Récupère et vide la file des SMS reçus en arrière-plan.
  /// Chaque entrée : {'sender': String, 'body': String, 'timestamp': int}.
  Future<List<IncomingSms>> drainPending() async {
    final raw = await _method.invokeMethod<List<dynamic>>('drainPending');
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((m) => IncomingSms(
              sender: (m['sender'] ?? '').toString(),
              body: (m['body'] ?? '').toString(),
              timestamp: (m['timestamp'] is int)
                  ? m['timestamp'] as int
                  : int.tryParse('${m['timestamp']}') ?? 0,
            ))
        .toList();
  }
}

/// Représente un SMS reçu en arrière-plan, drainé depuis le natif.
class IncomingSms {
  final String sender;
  final String body;

  /// Horodatage natif en millisecondes depuis l'epoch.
  final int timestamp;

  IncomingSms({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  /// Date de réception, dérivée de [timestamp].
  DateTime get ts => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
