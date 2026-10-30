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

  /// Fenêtre de dédup conso : ne sert qu'à fusionner le doublon « même SMS vu
  /// par readsms ET par le natif » (écart de quelques secondes). Au-delà, deux
  /// relevés de même valeur sont considérés DISTINCTS et tous deux conservés.
  static const Duration consumptionDedupWindow = Duration(seconds: 45);

  /// Vrai si [kwh] reçu à [at] est un doublon d'un relevé déjà présent dans
  /// [existing] (même valeur dans la [window]). Partagé par le chemin natif ET
  /// le chemin temps réel readsms, pour une dédup cohérente entre les deux.
  static bool isDuplicateConsumption(
    List<ConsumptionModel> existing,
    double kwh,
    DateTime at, {
    Duration window = consumptionDedupWindow,
  }) {
    return existing.any(
        (c) => c.kwh == kwh && at.difference(c.timestamp).abs() <= window);
  }

  /// Traite un SMS. Retourne le numéro du kit concerné dès que l'expéditeur
  /// correspond à un kit connu (afin que le SMS brut puisse être réinjecté dans
  /// le flux temps réel, ex. confirmation de config), ou null si l'expéditeur
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

    // 1) Consommation : reconnaît les deux formats du kit, « <nombre> kWh »
    //    ET « cons:<nombre> » / « consommation <nombre> » (parseur central
    //    partagé avec le flux temps réel, pour éviter toute divergence).
    final kwh = SmsParser.extractConsumption(sms.body);
    if (kwh != null) {
      final existing = await consumptionRepo.getAllConsumptions(kitNumber: kitNumber);
      // Dédup : collapse UNIQUEMENT le même SMS physique vu par les DEUX chemins
      // (temps réel `readsms` + natif), qui arrivent à quelques secondes d'écart.
      // Fenêtre VOLONTAIREMENT COURTE : le kit renvoie souvent la MÊME valeur
      // (ex. « 0.50 kWh » répété, « 0.05 kWh » 3 fois) ; une fenêtre large
      // (l'ancienne de 3 min) jetait ces relevés légitimes → conso « aléatoire ».
      final dup = isDuplicateConsumption(existing, kwh, sms.ts);
      if (!dup) {
        await consumptionRepo.addConsumption(
          ConsumptionModel(kwh: kwh, timestamp: sms.ts, kitNumber: kitNumber),
        );
      }
    }

    // 2) Accusé de réception ligne : "rNon" / "rNoff" où N = NUMÉRO DE LIGNE
    //    (1..N) tel que reconnu par le kit, et NON l'id base. On mappe donc N
    //    vers la vraie ligne du kit = la N-ième ligne (par ordre de création).
    // « of » (1 f, langage du kit) ou « off » sont acceptés pour l'extinction.
    final matches = RegExp(r'r(\d+)\s*(on|off?)', caseSensitive: false)
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

    // 3) ÉCHO DE CONFIGURATION : le kit renvoie la trame qu'il a reçue. Si elle
    //    concorde avec celle que l'application lui a envoyée, la configuration
    //    passe « en attente de validation » par l'utilisateur.
    //    Cet état est PERSISTÉ ici parce que cet écho arrive très souvent
    //    APPLICATION FERMÉE (récepteur natif) : c'est lui qui fera ressortir le
    //    bouton de validation au prochain lancement si la popup a été manquée.
    final pending = kit.pendingConfigMsg;
    if (kitNumber != null &&
        pending != null &&
        pending.isNotEmpty &&
        !kit.configAckPending &&
        SmsParser.configEchoMatches(sms.body, pending)) {
      await kitRepo.markConfigAckPending(kitNumber);
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
