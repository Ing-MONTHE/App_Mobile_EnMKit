// Tests unitaires de la logique cœur d'EnMKit (sans dépendance à la base ni au
// binding Flutter) : le modèle d'accusé de réception et l'analyse des échos du
// kit (« rXon » / « rXoff »), pierre angulaire de l'historique des accusés.

import 'package:flutter_test/flutter_test.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/core/utils/sms_parser.dart';

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

  group('Analyse des échos du kit (rXon / rXoff)', () {
    // Même expression que processIncomingSms / SmsInboxProcessor.
    final ackRegex = RegExp(r'r(\d+)\s*(on|off)', caseSensitive: false);

    test('reconnaît un accusé simple « r4on »', () {
      final m = ackRegex.firstMatch('r4on'.toLowerCase());
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), 4);
      expect(m.group(2), 'on');
    });

    test('reconnaît « r12off » (numéro à plusieurs chiffres)', () {
      final m = ackRegex.firstMatch('r12off');
      expect(int.parse(m!.group(1)!), 12);
      expect(m.group(2), 'off');
    });

    test('extrait plusieurs accusés d\'un même SMS', () {
      final all = ackRegex.allMatches('r4on;r5off'.toLowerCase()).toList();
      expect(all.length, 2);
      expect(all[1].group(1), '5');
      expect(all[1].group(2), 'off');
    });

    test('ignore un message qui n\'est pas un accusé de ligne', () {
      expect(ackRegex.hasMatch('120 kWh'), false);
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
}
