import 'dart:async';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/viewmodels/consumption_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:readsms/readsms.dart';
import 'package:permission_handler/permission_handler.dart';

/// Statut de la dernière demande de consommation, pour le retour visuel UI.
enum ConsumptionStatus { idle, waiting, received, timeout }

/// Joignabilité du kit (ping « hello ») : inconnue, vérification en cours,
/// joignable (le kit a répondu) ou injoignable (aucune réponse / pas de SMS).
enum KitReachability { unknown, checking, reachable, unreachable }

class SmsListenerViewModel extends ChangeNotifier {

  final _consumptionRepo = ConsumptionRepository(DBService());
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

  /// Tampon des derniers SMS de confiance reçus (horodatés), tous chemins
  /// confondus (temps réel + natif). Sert de FILET pour les attentes d'accusé :
  /// si la réponse du kit arrive juste avant/à la limite de l'abonnement, on la
  /// retrouve ici au lieu de la manquer. Purgé au-delà de quelques minutes.
  final List<MapEntry<DateTime, String>> _recentTrusted = [];

  void _recordTrusted(String body) {
    if (body.isEmpty) return;
    final now = DateTime.now();
    _recentTrusted.add(MapEntry(now, body));
    _recentTrusted
        .removeWhere((e) => now.difference(e.key) > const Duration(minutes: 5));
    if (_recentTrusted.length > 40) _recentTrusted.removeAt(0);
  }

  /// Flux des SMS reçus provenant uniquement du kit (numéro de confiance)
  Stream<String> get trustedSms$ => _trustedSmsController.stream;

  /// Réinjecte dans le flux temps réel un SMS de kit reçu par le CHEMIN NATIF
  /// (drain d'arrière-plan). Indispensable pour que les attentes d'accusé
  /// (confirmation de config, joignabilité…) le voient même quand le flux
  /// `readsms` n'a rien émis — le natif étant la voie de réception fiable.
  /// On n'appelle PAS [_processTrustedSms] ici : la persistance (conso/accusés)
  /// est déjà faite côté natif ; on ne fait qu'émettre + marquer « joignable ».
  void injectTrustedSms(String body) {
    if (body.isEmpty) return;
    if (_reachability == KitReachability.checking) {
      _reachability = KitReachability.reachable;
      _reachabilityTimer?.cancel();
      notifyListeners();
    }
    _recordTrusted(body);
    _trustedSmsController.add(body);
  }

  // Fenêtre d'acceptation de réponse consommation
  bool _awaitingConsumption = false;
  DateTime? _awaitConsumptionUntil;

  // Statut exposé à l'UI (état d'attente + timeout).
  ConsumptionStatus _consumptionStatus = ConsumptionStatus.idle;
  ConsumptionStatus get consumptionStatus => _consumptionStatus;
  Timer? _consumptionUiTimer;

  // Joignabilité du kit (ping « hello »).
  KitReachability _reachability = KitReachability.unknown;
  KitReachability get reachability => _reachability;
  Timer? _reachabilityTimer;

  /// Arme un test de joignabilité : on bascule en « vérification », et sans
  /// réponse du kit avant [uiTimeout] on conclut « injoignable ». Toute réponse
  /// du kit (n'importe quel SMS de confiance) repasse en « joignable ».
  void armReachabilityCheck({Duration uiTimeout = const Duration(seconds: 45)}) {
    _reachability = KitReachability.checking;
    _reachabilityTimer?.cancel();
    _reachabilityTimer = Timer(uiTimeout, () {
      if (_reachability == KitReachability.checking) {
        _reachability = KitReachability.unreachable;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Arme l'écoute d'une réponse de consommation.
  /// [window] : durée pendant laquelle une réponse tardive est encore acceptée
  /// et enregistrée (la donnée reste valable). [uiTimeout] : délai au bout
  /// duquel, sans réponse, l'UI bascule en « timeout » (plus court, pour ne pas
  /// laisser l'utilisateur attendre indéfiniment ; une réponse arrivant ensuite
  /// dans [window] repassera quand même en « reçu »).
  void armConsumptionWindow({
    Duration window = const Duration(minutes: 1),
    Duration uiTimeout = const Duration(seconds: 60),
  }) {
    _awaitingConsumption = true;
    _awaitConsumptionUntil = DateTime.now().add(window);
    _consumptionStatus = ConsumptionStatus.waiting;
    _consumptionUiTimer?.cancel();
    _consumptionUiTimer = Timer(uiTimeout, () {
      if (_consumptionStatus == ConsumptionStatus.waiting) {
        _consumptionStatus = ConsumptionStatus.timeout;
        notifyListeners();
      }
    });
    notifyListeners();
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
          final body = event.body;
          // Toute réponse du kit prouve qu'il est joignable par SMS.
          if (_reachability == KitReachability.checking) {
            _reachability = KitReachability.reachable;
            _reachabilityTimer?.cancel();
          }
          // Ne pas écraser lastSms par défaut; confier l'affichage à _processTrustedSms
          _recordTrusted(body);
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
            // Rattache la mesure au kit courant et n'enregistre qu'UNE fois :
            // le ViewModel scopé persiste en base ET met l'UI à jour. Sans VM
            // (cas limite), on retombe sur le repository directement.
            final model = ConsumptionModel(
              kwh: parsed,
              timestamp: DateTime.now(),
              kitNumber: kitNumber,
            );
            if (consumptionVM != null) {
              consumptionVM!.addConsumption(model);
            } else {
              _consumptionRepo.addConsumption(model);
            }
            lastSms = "$parsed kWh";
            // Considère la première réponse comme consumée et ferme la fenêtre
            _awaitingConsumption = false;
            _awaitConsumptionUntil = null;
            _consumptionStatus = ConsumptionStatus.received;
            _consumptionUiTimer?.cancel();
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

  /// Attend la confirmation d'une configuration : pour CHAQUE paire attendue
  /// [expected] (clé « n1 »/« n2 »/« en »/« ip » → valeur envoyée), le kit doit
  /// ré-écho la clé avec une valeur équivalente. La comparaison est TOLÉRANTE
  /// (espaces, casse, format numérique, format de numéro) car le kit renvoie ses
  /// accusés avec un format variable — cf. [SmsParser.configAckMatches]. Les
  /// paires peuvent arriver sur un seul SMS ou plusieurs. Retourne true si TOUTES
  /// sont confirmées avant [totalTimeout].
  Future<bool> waitForConfigAck(
    Map<String, String> expected, {
    Duration totalTimeout = const Duration(seconds: 120),
  }) async {
    if (expected.isEmpty) return true;
    final remaining = Map<String, String>.from(expected);

    final completer = Completer<bool>();
    StreamSubscription? sub;
    Timer? timer;
    Timer? poll;

    void finish(bool ok) {
      if (completer.isCompleted) return;
      timer?.cancel();
      poll?.cancel();
      sub?.cancel();
      completer.complete(ok);
    }

    void consume(String msg) {
      remaining
          .removeWhere((key, val) => SmsParser.configAckMatches(msg, key, val));
      if (remaining.isEmpty) finish(true);
    }

    // Balaye le tampon récent (≤3 min) — capte une réponse déjà arrivée.
    void scanBuffer() {
      final cut = DateTime.now().subtract(const Duration(minutes: 3));
      for (final e in List.of(_recentTrusted)) {
        if (e.key.isBefore(cut)) continue;
        consume(e.value);
        if (completer.isCompleted) return;
      }
    }

    // 1) Réponse déjà reçue avant l'abonnement ?
    scanBuffer();
    if (completer.isCompleted) return completer.future;

    // 2) Flux temps réel (readsms + natif réinjecté) …
    sub = trustedSms$.listen(consume);
    // 3) … ET re-scan périodique du tampon : FILET robuste, indépendant du
    //    timing du flux (le chemin natif alimente toujours le tampon).
    poll = Timer.periodic(const Duration(seconds: 2), (_) => scanBuffer());
    // 4) Délai global.
    timer = Timer(totalTimeout, () => finish(false));

    return completer.future;
  }

  @override
  void dispose() {
    _consumptionUiTimer?.cancel();
    _reachabilityTimer?.cancel();
    _trustedSmsController.close();
    super.dispose();
  }
}
