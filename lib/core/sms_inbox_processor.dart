import 'package:enmkit/core/background_sms_bridge.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';

/// Traite les SMS entrants drainés depuis le natif et met à jour la base, en
/// rattachant chaque message au bon kit (multi-kits). Logique côté Dart pour
/// garder l'architecture clean : le natif ne fait que capter et empiler.
class SmsInboxProcessor {
  final KitRepository kitRepo;
  final ConsumptionRepository consumptionRepo;
  final RelayRepository relayRepo;

  SmsInboxProcessor({
    required this.kitRepo,
    required this.consumptionRepo,
    required this.relayRepo,
  });

  /// Traite un SMS. Retourne le numéro du kit concerné dès que l'expéditeur
  /// correspond à un kit connu (afin que le SMS brut puisse être réinjecté dans
  /// le flux temps réel — ex. confirmation de config), ou null si l'expéditeur
  /// n'est pas un kit. La consommation et les accusés de ligne sont persistés
  /// au passage.
  Future<String?> process(IncomingSms sms) async {
    final kits = await kitRepo.getKit();
    KitModel? kit;
    for (final k in kits) {
      if (_match(sms.sender, k.kitNumber)) {
        kit = k;
        break;
      }
    }
    if (kit == null) return null;
    final kitNumber = kit.kitNumber;

    // 1) Consommation : reconnaît les deux formats du kit — « <nombre> kWh »
    //    ET « cons:<nombre> » / « consommation <nombre> » (parseur central
    //    partagé avec le flux temps réel, pour éviter toute divergence).
    final kwh = SmsParser.extractConsumption(sms.body);
    if (kwh != null) {
      final existing = await consumptionRepo.getAllConsumptions(kitNumber: kitNumber);
      // Dédup : évite un doublon si le même relevé a déjà été enregistré
      // (ex. par le flux temps réel) à quelques minutes près.
      final dup = existing.any((c) =>
          c.kwh == kwh && sms.ts.difference(c.timestamp).inMinutes.abs() <= 3);
      if (!dup) {
        await consumptionRepo.addConsumption(
          ConsumptionModel(kwh: kwh, timestamp: sms.ts, kitNumber: kitNumber),
        );
      }
    }

    // 2) Accusé de réception ligne : "rNon" / "rNoff" où N = NUMÉRO DE LIGNE
    //    (1..N) tel que reconnu par le kit, et NON l'id base. On mappe donc N
    //    vers la vraie ligne du kit = la N-ième ligne (par ordre de création).
    final matches = RegExp(r'r(\d+)\s*(on|off)', caseSensitive: false)
        .allMatches(sms.body.toLowerCase());
    if (matches.isNotEmpty) {
      // Lignes du kit triées par id = ordre de création => position = n° ligne.
      final relays = await relayRepo.getAllRelays(kitNumber: kitNumber);
      relays.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      for (final m in matches) {
        final line = int.tryParse(m.group(1)!);
        if (line == null || line < 1 || line > relays.length) continue;
        final relay = relays[line - 1];
        final rid = relay.id;
        if (rid == null) continue;
        final isOn = m.group(2) == 'on';
        // Reflète l'état réel ON/OFF de la ligne…
        await relayRepo.applyKitAck(rid, isActive: isOn, kitNumber: kitNumber);
        // …ET journalise l'accusé horodaté (écrivain UNIQUE de l'historique).
        await relayRepo.addAck(RelayAck(
          relayId: rid,
          kitNumber: kitNumber,
          isActive: isOn,
          at: sms.ts,
          raw: sms.body.trim(),
        ));
      }
    }

    return kitNumber;
  }

  bool _match(String? a, String? b) {
    final ta = _tail(a);
    final tb = _tail(b);
    return ta.isNotEmpty && ta == tb;
  }

  String _tail(String? n) {
    if (n == null) return '';
    final d = n.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length > 8 ? d.substring(d.length - 8) : d;
  }
}
