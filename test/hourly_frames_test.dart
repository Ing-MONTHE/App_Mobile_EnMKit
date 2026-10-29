// Trames horaires « JJ/MM/AA;HH;KWH » (contrat §2) : extraction, rejets, et
// non-régression des parseurs existants (conso legacy, accusés, écho config).

import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmsParser.parseHourlyFrames', () {
    test('exemple du contrat : deux lignes', () {
      final r = SmsParser.parseHourlyFrames('27/06/26;09;0.00\n27/06/26;10;0.12');
      expect(r.frames.length, 2);
      expect(r.rejectedLines, 0);
      expect(r.frames[0].hourStart, DateTime(2026, 6, 27, 9));
      expect(r.frames[0].kwh, 0.0);
      expect(r.frames[0].hourKey, '2026-06-27T09:00:00');
      expect(r.frames[1].hourStart, DateTime(2026, 6, 27, 10));
      expect(r.frames[1].kwh, 0.12);
    });

    test('ligne unique de l\'exemple « 27/06/26;09;0.00 »', () {
      final r = SmsParser.parseHourlyFrames('27/06/26;09;0.00');
      expect(r.frames.single.hourKey, '2026-06-27T09:00:00');
    });

    test('virgule décimale et heure sur un chiffre', () {
      final r = SmsParser.parseHourlyFrames('01/07/26;7;1,25');
      expect(r.frames.single.hourStart, DateTime(2026, 7, 1, 7));
      expect(r.frames.single.kwh, 1.25);
    });

    test('CRLF, espaces autour et texte parasite : seules les lignes conformes',
        () {
      const body = 'EnMKit kit 12\r\n  27/06/26;09;0.10  \r\n'
          'bonjour\r\n27/06/26;10;0.20\r\nFIN';
      final r = SmsParser.parseHourlyFrames(body);
      expect(r.frames.map((f) => f.kwh), [0.10, 0.20]);
      expect(r.rejectedLines, 0); // le texte n'est pas une trame ratée
    });

    test('heure invalide (24, 99) : rejetée et comptée', () {
      final r =
          SmsParser.parseHourlyFrames('27/06/26;24;0.10\n27/06/26;99;0.1\n27/06/26;23;0.3');
      expect(r.frames.single.hourStart.hour, 23);
      expect(r.rejectedLines, 2);
    });

    test('date impossible (31/02, mois 13, jour 00) : rejetée et comptée', () {
      final r = SmsParser.parseHourlyFrames(
          '31/02/26;10;0.10\n10/13/26;10;0.1\n00/06/26;10;0.1\n29/02/28;10;0.5');
      // 29/02/2028 existe (année bissextile).
      expect(r.frames.single.hourStart, DateTime(2028, 2, 29, 10));
      expect(r.rejectedLines, 3);
    });

    test('valeur négative ou non numérique : rejetée', () {
      final r = SmsParser.parseHourlyFrames(
          '27/06/26;09;-0.10\n27/06/26;10;abc\n27/06/26;11;0.4');
      expect(r.frames.single.kwh, 0.4);
      expect(r.rejectedLines, 2);
    });

    test('lignes « poubelle » sans rapport : aucune trame', () {
      final r = SmsParser.parseHourlyFrames('r1on\nn1:+237699000000\n0.5 kWh\n');
      expect(r.isEmpty, isTrue);
      expect(r.rejectedLines, 0);
    });

    test('même heure répétée dans un SMS : la dernière valeur gagne', () {
      final r = SmsParser.parseHourlyFrames('27/06/26;09;0.10\n27/06/26;09;0.30');
      expect(r.frames.single.kwh, 0.30);
    });

    test('trames triées chronologiquement', () {
      final r = SmsParser.parseHourlyFrames('28/06/26;00;0.1\n27/06/26;23;0.2');
      expect(r.frames.first.hourStart, DateTime(2026, 6, 27, 23));
    });
  });

  group('Non-régression : les trames ne déclenchent pas les autres parseurs', () {
    const frames = '27/06/26;09;0.00\n27/06/26;10;0.12';

    test('extractConsumption ignore un SMS de trames', () {
      expect(SmsParser.extractConsumption(frames), isNull);
      expect(SmsParser.extractConsumption('JJ/MM/AA;HH;KWH\n$frames'), isNull);
      // Même si une trame est suivie d'un texte « kWh » sur une autre ligne.
      expect(SmsParser.extractConsumption('$frames\ntotal 3 kWh'), isNull);
    });

    test('extractConsumption fonctionne toujours sur un relevé legacy', () {
      expect(SmsParser.extractConsumption('Consommation : 0.05 KWh'), 0.05);
      expect(SmsParser.extractConsumption('cons:12.5'), 12.5);
    });

    test('accusés de ligne et écho de config ne sont pas des trames', () {
      expect(SmsParser.containsHourlyFrames('r1on;r2of'), isFalse);
      expect(
          SmsParser.containsHourlyFrames(
              'n1:+237695864083:n2::en:110.0:ip:1000'),
          isFalse);
      // …et inversement une trame n'est ni un accusé ni un écho de config.
      final ack = RegExp(r'r(\d+)\s*(on|off?)', caseSensitive: false);
      expect(ack.hasMatch(frames), isFalse);
      expect(
          SmsParser.configEchoMatches(
              frames, 'n1:+237695864083:n2::en:110.0:ip:1000'),
          isFalse);
    });
  });
}
