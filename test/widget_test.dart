// Tests unitaires de la logique cœur d'EnMKit (sans dépendance à la base ni au
// binding Flutter) : le modèle d'accusé de réception et l'analyse des échos du
// kit (« rXon » / « rXoff »), pierre angulaire de l'historique des accusés.

import 'package:flutter_test/flutter_test.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/core/utils/ack_logic.dart';
import 'package:enmkit/core/sms_inbox_processor.dart';
import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/core/sms_service_hybrid.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/support_service.dart';

void main() {
  group('RelayAck — sérialisation', () {
    test('toMap / fromMap conservent toutes les valeurs (dont le texte brut)',
        () {
      final at = DateTime.fromMillisecondsSinceEpoch(1781388905969);
      final ack = RelayAck(
        relayId: 4,
        kitNumber: '+237690112233',
        isActive: true,
        at: at,
        raw: 'r4on',
      );

      final restored = RelayAck.fromMap(ack.toMap());

      expect(restored.relayId, 4);
      expect(restored.kitNumber, '+237690112233');
      expect(restored.isActive, true);
      expect(restored.at, at);
      expect(restored.raw, 'r4on'); // l'accusé reçu intégral est bien conservé
    });

    test('isActive est encodé en 0/1 et relu correctement', () {
      final off = RelayAck(
        relayId: 2,
        kitNumber: null,
        isActive: false,
        at: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(off.toMap()['isActive'], 0);
      expect(RelayAck.fromMap(off.toMap()).isActive, false);
    });
  });

  group('Analyse des échos du kit (rXon / rXof)', () {
    // Même expression que processIncomingSms / SmsInboxProcessor.
    // « of » (1 f, langage du kit) ET « off » sont acceptés pour l'extinction.
    final ackRegex = RegExp(r'r(\d+)\s*(on|off?)', caseSensitive: false);
    bool isOn(RegExpMatch m) => m.group(2) == 'on';

    test('reconnaît un accusé simple « r4on »', () {
      final m = ackRegex.firstMatch('r4on'.toLowerCase());
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), 4);
      expect(isOn(m), true);
    });

    test('reconnaît l\'extinction « r4of » (1 f, langage du kit)', () {
      final m = ackRegex.firstMatch('r4of');
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), 4);
      expect(isOn(m), false);
    });

    test('reconnaît aussi « r12off » (tolérance 2 f)', () {
      final m = ackRegex.firstMatch('r12off');
      expect(int.parse(m!.group(1)!), 12);
      expect(isOn(m), false);
    });

    test('extrait plusieurs accusés d\'un même SMS', () {
      final all = ackRegex.allMatches('r4on;r5of'.toLowerCase()).toList();
      expect(all.length, 2);
      expect(all[1].group(1), '5');
      expect(isOn(all[1]), false);
    });

    test('ignore un message qui n\'est pas un accusé de ligne', () {
      expect(ackRegex.hasMatch('120 kWh'), false);
    });
  });

  // Anti-doublon de l'historique mémoire : quand un accusé arrive en premier
  // plan, on l'insère pour un affichage instantané — sans empiler de doublon si
  // le même SMS est rejoué (reconstruction) ou déjà rechargé depuis la base.
  group('AckLogic.isDuplicate (fenêtre 30 s)', () {
    RelayAck ack(bool on, DateTime at) =>
        RelayAck(relayId: 1, kitNumber: null, isActive: on, at: at);
    final t0 = DateTime.fromMillisecondsSinceEpoch(1782000000000);

    test('liste vide => jamais un doublon', () {
      expect(AckLogic.isDuplicate(const [], true, t0), isFalse);
    });

    test('même état dans la fenêtre => doublon (on n\'insère pas)', () {
      final existing = [ack(true, t0)];
      expect(
          AckLogic.isDuplicate(
              existing, true, t0.add(const Duration(seconds: 10))),
          isTrue);
    });

    test('même état hors fenêtre => pas un doublon (on insère)', () {
      final existing = [ack(true, t0)];
      expect(
          AckLogic.isDuplicate(
              existing, true, t0.add(const Duration(seconds: 31))),
          isFalse);
    });

    test('état différent dans la fenêtre => pas un doublon (on insère)', () {
      final existing = [ack(true, t0)];
      expect(
          AckLogic.isDuplicate(
              existing, false, t0.add(const Duration(seconds: 5))),
          isFalse);
    });

    test('doublon détecté même si l\'accusé existant est postérieur', () {
      // Les données peuvent porter un horodatage futur (jeu de test) : on
      // compare en valeur absolue, le doublon est tout de même reconnu.
      final existing = [ack(false, t0.add(const Duration(seconds: 10)))];
      expect(AckLogic.isDuplicate(existing, false, t0), isTrue);
    });
  });

  // Ouverture AUTOMATIQUE de la feuille de confirmation : doit s'ouvrir à
  // l'arrivée d'un accusé, absorber une RE-LIVRAISON quasi simultanée du même
  // accusé (readsms + chemin natif), mais rouvrir pour une vraie commande
  // identique répétée plus tard.
  group('AckLogic.isAutoOpenDuplicate (ouverture auto)', () {
    final t0 = DateTime.fromMillisecondsSinceEpoch(1782000000000);

    test('aucun accusé ouvert encore => pas un doublon (on ouvre)', () {
      expect(
        AckLogic.isAutoOpenDuplicate(
          lastRelayId: null,
          lastState: null,
          lastAt: null,
          relayId: 1,
          isOn: true,
          at: t0,
        ),
        isFalse,
      );
    });

    test('même ligne + même état dans la fenêtre => doublon (on n\'ouvre pas)',
        () {
      expect(
        AckLogic.isAutoOpenDuplicate(
          lastRelayId: 1,
          lastState: true,
          lastAt: t0,
          relayId: 1,
          isOn: true,
          at: t0.add(const Duration(seconds: 5)),
        ),
        isTrue,
      );
    });

    test('même ligne + même état hors fenêtre => pas un doublon (on rouvre)',
        () {
      expect(
        AckLogic.isAutoOpenDuplicate(
          lastRelayId: 1,
          lastState: true,
          lastAt: t0,
          relayId: 1,
          isOn: true,
          at: t0.add(const Duration(seconds: 21)),
        ),
        isFalse,
      );
    });

    test('état différent dans la fenêtre => pas un doublon (on rouvre)', () {
      expect(
        AckLogic.isAutoOpenDuplicate(
          lastRelayId: 1,
          lastState: true,
          lastAt: t0,
          relayId: 1,
          isOn: false,
          at: t0.add(const Duration(seconds: 5)),
        ),
        isFalse,
      );
    });

    test('ligne différente dans la fenêtre => pas un doublon (on rouvre)', () {
      expect(
        AckLogic.isAutoOpenDuplicate(
          lastRelayId: 1,
          lastState: true,
          lastAt: t0,
          relayId: 2,
          isOn: true,
          at: t0.add(const Duration(seconds: 5)),
        ),
        isFalse,
      );
    });
  });

  // Le kit peut répondre à « cons » sous plusieurs formes. Le parseur DOIT
  // capter chacune, sinon la mesure est perdue en arrière-plan (app fermée).
  group('Réception de la consommation (réponse du kit à « cons »)', () {
    test('format « <nombre> kWh »', () {
      expect(SmsParser.extractConsumption('12.5 kWh'), 12.5);
      expect(SmsParser.extractConsumption('Conso actuelle : 340 kWh'), 340);
    });

    test('virgule décimale (locale FR) « 12,5 kWh »', () {
      expect(SmsParser.extractConsumption('12,5 kWh'), 12.5);
    });

    test('format « cons:<nombre> » SANS le mot kWh (filet arrière-plan)', () {
      expect(SmsParser.extractConsumption('cons:12.5'), 12.5);
      expect(SmsParser.extractConsumption('cons=89'), 89);
      expect(SmsParser.extractConsumption('cons: 7,25'), 7.25);
    });

    test('format « consommation <nombre> »', () {
      expect(SmsParser.extractConsumption('consommation = 200'), 200);
      expect(SmsParser.extractConsumption('Consommation: 18,4'), 18.4);
    });

    test('format réel du kit « Consommation : 0.05 KWh »', () {
      expect(SmsParser.extractConsumption('Consommation : 0.05 KWh'), 0.05);
      expect(SmsParser.extractConsumption('Consommation : 10.8 KWh'), 10.8);
      expect(SmsParser.extractConsumption('Consommation : 1,7 KWh'), 1.7);
    });

    test('ne capte rien sur la requête « cons » nue (sans chiffre)', () {
      expect(SmsParser.extractConsumption('cons'), isNull);
    });

    test('ne confond pas un accusé de ligne « r4on » avec une conso', () {
      expect(SmsParser.extractConsumption('r4on'), isNull);
    });

    test('ne confond pas un écho de config « ip:1000 » avec une conso', () {
      expect(SmsParser.extractConsumption('ip:1000'), isNull);
      expect(SmsParser.extractConsumption('n1:237690112233'), isNull);
    });
  });

  // Dédup conso : le kit renvoie souvent la MÊME valeur (« 0.50 kWh » répété).
  // La fenêtre courte ne doit fusionner QUE le même SMS vu par les deux chemins
  // (readsms + natif, à quelques secondes), pas des relevés légitimes espacés.
  group('Dédup consommation (fenêtre courte)', () {
    final t0 = DateTime(2026, 6, 22, 10, 0, 0);
    final existing = [ConsumptionModel(kwh: 0.50, timestamp: t0)];

    test('même valeur à 3 s = doublon (même SMS, deux chemins)', () {
      final at = t0.add(const Duration(seconds: 3));
      expect(SmsInboxProcessor.isDuplicateConsumption(existing, 0.50, at),
          isTrue);
    });

    test('même valeur 1 min plus tard = relevé distinct CONSERVÉ', () {
      final at = t0.add(const Duration(minutes: 1));
      expect(SmsInboxProcessor.isDuplicateConsumption(existing, 0.50, at),
          isFalse);
    });

    test('valeur différente dans la fenêtre = conservée', () {
      final at = t0.add(const Duration(seconds: 3));
      expect(SmsInboxProcessor.isDuplicateConsumption(existing, 0.51, at),
          isFalse);
    });

    test('historique vide = jamais doublon', () {
      expect(SmsInboxProcessor.isDuplicateConsumption([], 0.50, t0), isFalse);
    });
  });

  // Le kit ré-écho la config avec un format variable : la confirmation doit
  // rester tolérante (sinon « délai dépassé » alors que le kit a confirmé).
  group('Confirmation de config (accusé tolérant)', () {
    test('écho concaténé exact', () {
      const echo = 'n1:+237699173771;n2:+237690112233;en:300.0;ip:1000';
      expect(SmsParser.configAckMatches(echo, 'n1', '+237699173771'), isTrue);
      expect(SmsParser.configAckMatches(echo, 'en', '300.0'), isTrue);
      expect(SmsParser.configAckMatches(echo, 'ip', '1000'), isTrue);
    });

    test('tolère les espaces après les deux-points', () {
      expect(SmsParser.configAckMatches('en: 300.0', 'en', '300.0'), isTrue);
      expect(SmsParser.configAckMatches('ip : 1000', 'ip', '1000'), isTrue);
    });

    test('équivalence numérique 300 == 300.0', () {
      expect(SmsParser.configAckMatches('en:300', 'en', '300.0'), isTrue);
      expect(SmsParser.configAckMatches('en:300.0', 'en', '300'), isTrue);
    });

    test('tolère un suffixe kWh', () {
      expect(SmsParser.configAckMatches('en: 300 kWh', 'en', '300.0'), isTrue);
    });

    test('numéro comparé sur les chiffres', () {
      expect(
          SmsParser.configAckMatches('n1:699173771', 'n1', '+237699173771'),
          isTrue);
    });

    test('mauvaise valeur => pas de correspondance', () {
      expect(SmsParser.configAckMatches('en:250.0', 'en', '300.0'), isFalse);
      expect(SmsParser.configAckMatches('ip:500', 'ip', '1000'), isFalse);
    });

    test('clé absente => pas de correspondance', () {
      expect(SmsParser.configAckMatches('ip:1000', 'en', '300.0'), isFalse);
    });

    test('écho « : »-séparé (syntaxe réelle du kit)', () {
      const echo = 'n1:+237656853629:n2:+237690731603:en:10.8:ip:1000';
      expect(SmsParser.configAckMatches(echo, 'n1', '+237656853629'), isTrue);
      expect(SmsParser.configAckMatches(echo, 'n2', '+237690731603'), isTrue);
      expect(SmsParser.configAckMatches(echo, 'en', '10.8'), isTrue);
      expect(SmsParser.configAckMatches(echo, 'ip', '1000'), isTrue);
      // une valeur erronée n'est pas confirmée par erreur
      expect(SmsParser.configAckMatches(echo, 'en', '10.9'), isFalse);
    });
  });

  // La trame de config est à STRUCTURE FIXE : les quatre marqueurs partent
  // toujours, dans l'ordre, un champ non renseigné valant VIDE. Le kit repère
  // ses champs par marqueur : une trame amputée n'est pas parsée, donc pas
  // appliquée et pas accusée.
  group('Trame de configuration (n1/n2/en/ip)', () {
    // buildConcatenatedConfig est pur : il ne touche jamais au dépôt.
    final sms = SmsServiceHybrid(KitRepository(DBService()));

    test('2e numéro non renseigné => « n2:: » présent mais vide', () {
      expect(
        sms.buildConcatenatedConfig(
          firstPhone: '+237695864083',
          secondPhone: null,
          initialConsumption: 110.0,
          pulsation: 1000,
        ),
        'n1:+237695864083:n2::en:110.0:ip:1000',
      );
    });

    test('2e numéro vide (chaîne vide) => même trame que non renseigné', () {
      expect(
        sms.buildConcatenatedConfig(
          firstPhone: '695864083',
          secondPhone: '',
          initialConsumption: 110.0,
          pulsation: 1000,
        ),
        'n1:+237695864083:n2::en:110.0:ip:1000',
      );
    });

    test('les deux numéros renseignés => trame complète', () {
      expect(
        sms.buildConcatenatedConfig(
          firstPhone: '+237656853629',
          secondPhone: '+237690731603',
          initialConsumption: 10.8,
          pulsation: 1000,
        ),
        'n1:+237656853629:n2:+237690731603:en:10.8:ip:1000',
      );
    });

    test('aucun numéro => les deux marqueurs restent, vides', () {
      expect(
        sms.buildConcatenatedConfig(
          initialConsumption: 0.0,
          pulsation: 1000,
        ),
        'n1::n2::en:0.0:ip:1000',
      );
    });

    test('un champ vide n\'est PAS attendu en accusé (sinon timeout)', () {
      final expected = sms.generateExpectedMessages(
        firstPhone: '+237695864083',
        secondPhone: '',
        initialConsumption: 110.0,
        pulsation: 1000,
      );
      expect(expected.containsKey('n2'), isFalse);
      expect(expected['n1'], 'n1:+237695864083');
      expect(expected['en'], 'en:110.0');
      expect(expected['ip'], 'ip:1000');
    });

    test('SmsParser.buildConfigCommand produit la même trame fixe', () {
      expect(
        SmsParser.buildConfigCommand(
          firstPhone: '+237695864083',
          initialConsumption: 110.0,
          pulsation: 1000,
        ),
        'n1:+237695864083:n2::en:110.0:ip:1000',
      );
    });
  });

  // Reconnaissance de l'écho que le kit renvoie après une configuration : c'est
  // lui qui déclenche la popup de validation, et qui fait ressortir le bouton
  // de rattrapage si elle a été manquée.
  group('Écho de configuration renvoyé par le kit', () {
    const sent = 'n1:+237695864083:n2::en:110.0:ip:1000';

    test('écho identique => concordance', () {
      expect(SmsParser.configEchoMatches(sent, sent), isTrue);
    });

    test('écho reformaté par le kit (espaces, casse, kWh, entier) => concordance',
        () {
      const echo = 'N1: +237695864083 : N2: : EN: 110 kWh : IP: 1000';
      expect(SmsParser.configEchoMatches(echo, sent), isTrue);
    });

    test('écho « ; »-séparé => concordance', () {
      const echo = 'n1:+237695864083;n2:;en:110.0;ip:1000';
      expect(SmsParser.configEchoMatches(echo, sent), isTrue);
    });

    test('numéro sans indicatif => concordance (8 derniers chiffres)', () {
      const echo = 'n1:695864083:n2::en:110.0:ip:1000';
      expect(SmsParser.configEchoMatches(echo, sent), isTrue);
    });

    test('une valeur différente => PAS de concordance', () {
      const echo = 'n1:+237695864083:n2::en:110.0:ip:900';
      expect(SmsParser.configEchoMatches(echo, sent), isFalse);
    });

    test('numéro différent => PAS de concordance', () {
      const echo = 'n1:+237690731603:n2::en:110.0:ip:1000';
      expect(SmsParser.configEchoMatches(echo, sent), isFalse);
    });

    test('le champ VIDE n\'est pas exigé dans l\'écho', () {
      // L'écho ne mentionne même pas n2 : la concordance tient quand même,
      // puisque l'utilisateur n'avait pas renseigné de 2e numéro.
      const echo = 'n1:+237695864083:en:110.0:ip:1000';
      expect(SmsParser.configEchoMatches(echo, sent), isTrue);
    });

    test('un SMS quelconque du kit ne vaut PAS concordance', () {
      expect(SmsParser.configEchoMatches('r2on', sent), isFalse);
      expect(SmsParser.configEchoMatches('0.05 kWh', sent), isFalse);
      expect(SmsParser.configEchoMatches('', sent), isFalse);
    });

    test('trame envoyée inexploitable => jamais de concordance', () {
      // Garde-fou : sans trame de référence valable, on ne confirme rien.
      expect(SmsParser.configEchoMatches('n1:+237695864083', 'bonjour'), isFalse);
      expect(SmsParser.configEchoMatches('n1::n2::en::ip:', 'n1::n2::en::ip:'),
          isFalse);
    });

    test('décomposition de la trame envoyée', () {
      expect(SmsParser.parseSentConfig(sent), {
        'n1': '+237695864083',
        'n2': '',
        'en': '110.0',
        'ip': '1000',
      });
      // Forme inattendue => aucune paire (on ne devine pas).
      expect(SmsParser.parseSentConfig('coucou:1'), <String, String>{});
    });
  });

  // Demande d'assistance : ce que le SUPPORT reçoit réellement. Le kit concerné
  // doit toujours y figurer, sans quoi le support ignore de quel boîtier il
  // s'agit.
  group("Demande d'assistance envoyée au support", () {
    test('configuration de numéro — suppression : tout est repris', () {
      final msg = SupportService.buildRequest(
        topic: SupportTopic.numberConfig,
        action: NumberAction.remove,
        targetNumber: '+237690112233',
        details: 'Ce numéro ne doit plus piloter le kit',
        kitNumber: '+237695864083',
        kitName: 'Appartement A',
      );
      expect(msg, contains('Kit : +237695864083 (Appartement A)'));
      expect(msg, contains("Objet : Configuration d'un numéro — Supprimer"));
      expect(msg, contains('Numéro concerné : +237690112233'));
      expect(msg, contains('Détail : Ce numéro ne doit plus piloter le kit'));
    });

    test('kit sans nom : le numéro seul suffit', () {
      final msg = SupportService.buildRequest(
        topic: SupportTopic.consumption,
        kitNumber: '+237695864083',
      );
      expect(msg, contains('Kit : +237695864083'));
      expect(msg, isNot(contains('(')));
      expect(msg,
          contains('Objet : Problème de réception de la consommation'));
    });

    test('champs vides : aucune ligne inutile', () {
      final msg = SupportService.buildRequest(
        topic: SupportTopic.other,
        targetNumber: '   ',
        details: '',
      );
      expect(msg, isNot(contains('Numéro concerné')));
      expect(msg, isNot(contains('Détail')));
      expect(msg, isNot(contains('Kit :')));
      expect(msg, contains('Objet : Autre demande'));
    });

    test("l'action n'apparaît que pour une configuration de numéro", () {
      final msg = SupportService.buildRequest(
        topic: SupportTopic.unreachable,
        action: NumberAction.add,
      );
      expect(msg, contains('Objet : Kit injoignable'));
      expect(msg, isNot(contains('Ajouter')));
    });

    test('reconnaissance du numéro du support, quel que soit son format', () {
      expect(SupportService.isSupportNumber('+237696372245'), isTrue);
      expect(SupportService.isSupportNumber('696372245'), isTrue);
      expect(SupportService.isSupportNumber('237 696 372 245'), isTrue);
      expect(SupportService.isSupportNumber('+237690112233'), isFalse);
      expect(SupportService.isSupportNumber(null), isFalse);
      expect(SupportService.isSupportNumber(''), isFalse);
    });
  });
}
