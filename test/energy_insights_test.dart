// Moteur d'analyse hors-ligne (contrat §6) : vecteur de référence partagé avec
// le backend Python, plus quelques cas limites.

import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vecteur de référence du contrat §6 : 28 jours, 0.05 kWh de 00 à 05 h, 0.20
/// de 06 à 17 h, 0.60 de 18 à 22 h, 0.10 à 23 h ; sauf le DERNIER jour à 20 h
/// : 2.00.
List<HourlyPoint> referenceVector(DateTime firstDay) {
  final out = <HourlyPoint>[];
  for (var d = 0; d < 28; d++) {
    for (var h = 0; h < 24; h++) {
      double v;
      if (h <= 5) {
        v = 0.05;
      } else if (h <= 17) {
        v = 0.20;
      } else if (h <= 22) {
        v = 0.60;
      } else {
        v = 0.10;
      }
      if (d == 27 && h == 20) v = 2.00;
      out.add(HourlyPoint(
          DateTime(firstDay.year, firstDay.month, firstDay.day + d, h), v));
    }
  }
  return out;
}

void main() {
  group('Vecteur de référence §6 (parité avec le backend Python)', () {
    // Mêmes entrées que EnMKit_platform/api/tests/test_analytics.py :
    // dernier jour du vecteur, toutes ses heures reçues.
    final now = DateTime(2026, 6, 28, 23, 30);
    final ins =
        EnergyInsightsEngine.compute(referenceVector(DateTime(2026, 6, 1)), now: now);
    final j = ins.toJson();

    test('base_load_kw = 0.05', () {
      expect(ins.baseLoadKw, closeTo(0.05, 1e-9));
    });

    test('peak_hour ∈ 18..22 avec médiane 0.60', () {
      expect(ins.peakHour, inInclusiveRange(18, 22));
      expect(ins.profile.global[ins.peakHour!].median, closeTo(0.60, 1e-9));
    });

    test('une seule anomalie « spike », au dernier jour 20 h', () {
      expect(ins.anomalies.length, 1);
      final a = ins.anomalies.single;
      expect(a.kind, AnomalyKind.spike);
      expect(a.hourStart, DateTime(2026, 6, 28, 20));
      expect(a.kwh, 2.0);
      expect(a.expectedKwh, closeTo(0.60, 1e-9));
      expect(a.z, greaterThan(3.5));
      expect((j['anomalies'] as List).first['hour_start'], '2026-06-28T20:00:00');
    });

    test('completeness = 1.0, 672 h attendues et reçues, aucun trou', () {
      expect(ins.dataQuality.expectedHours, 672);
      expect(ins.dataQuality.receivedHours, 672);
      expect(ins.dataQuality.completeness, 1.0);
      expect(ins.dataQuality.gaps, isEmpty);
    });

    test('moyenne journalière ≈ 5.80 kWh (±0.1)', () {
      expect(ins.avgDailyKwh, closeTo(5.80, 0.1));
      expect(ins.avgDailyKwh, closeTo(5.85, 1e-9)); // spike inclus
    });

    test('valeurs dérivées identiques au backend', () {
      expect(ins.baseLoadShare, closeTo(1.2 / 5.85, 1e-3));
      expect(ins.peakShare, closeTo(0.5214, 1e-3));
      expect(ins.trendPct, closeTo(0.0, 1e-9));
      expect(ins.forecast.todayKwh, closeTo(7.2, 1e-9));
      expect(ins.forecast.monthKwh, closeTo(175.5, 0.01));
      final nxt = j['forecast']['next_24h'] as List;
      expect(nxt.length, 24);
      expect(nxt.first, {'hour_start': '2026-06-29T00:00:00', 'kwh': 0.05});
      expect(nxt[20]['kwh'], closeTo(0.6, 1e-9));
      expect(j['score']['penalties'],
          {'standby': 20.5, 'peak': 17.1, 'trend': 0.0, 'anomalies': 4.0});
      expect(j['score']['value'], closeTo(58.4, 1e-9));
      expect(ins.score.grade, 'C');
      expect(ins.recommendations.map((r) => r.code).toList(),
          ['PEAK_HEAVY', 'ANOMALIES']);
    });

    test('sérialisation JSON aux clés du contrat', () {
      expect(j.keys.toSet(), {
        'kit_id', 'kit_number', 'generated_at', 'days', 'data_quality', 'profile',
        'anomalies', 'base_load_kw', 'base_load_share', 'peak_hour', 'peak_share',
        'trend_pct', 'avg_daily_kwh', 'forecast', 'score', 'recommendations',
      });
      expect((j['forecast'] as Map).keys.toSet(),
          {'next_24h', 'today_kwh', 'month_kwh', 'month_cost_fcfa'});
      expect((j['profile'] as Map).values.every((v) => (v as List).length == 24),
          isTrue);
    });
  });

  group('Cas limites', () {
    test('série vide : zéros, peak/trend null, seulement DATA_GAPS', () {
      final ins =
          EnergyInsightsEngine.compute(const [], now: DateTime(2026, 6, 29, 10));
      expect(ins.hasData, isFalse);
      expect(ins.dataQuality.completeness, 0.0);
      expect(ins.peakHour, isNull);
      expect(ins.trendPct, isNull);
      expect(ins.recommendations.map((r) => r.code).toList(), ['DATA_GAPS']);
    });

    test('trous de données détectés (plus récents d\'abord) + DATA_GAPS', () {
      final pts = referenceVector(DateTime(2026, 6, 1))
          .where((p) =>
              // trou de 5 h le 10/06 et toute la journée du 20/06
              !(p.hourStart.day == 10 && p.hourStart.hour >= 8 && p.hourStart.hour < 13) &&
              !(p.hourStart.day >= 20))
          .toList();
      final ins = EnergyInsightsEngine.compute(pts, now: DateTime(2026, 6, 28, 23, 30));
      final gaps = ins.dataQuality.gaps;
      expect(gaps.length, 2);
      expect(gaps.first.from, DateTime(2026, 6, 20, 0)); // le plus récent
      expect(gaps.first.to, DateTime(2026, 6, 28, 22)); // dernier créneau écoulé
      expect(gaps.first.hours, 8 * 24 + 23);
      expect(gaps.last.from, DateTime(2026, 6, 10, 8));
      expect(gaps.last.to, DateTime(2026, 6, 10, 12)); // borne incluse
      expect(gaps.last.hours, 5);
      expect(ins.dataQuality.completeness, lessThan(0.8));
      expect(ins.recommendations.map((r) => r.code), contains('DATA_GAPS'));
    });

    test('tout à 0 sur 24 h => ALL_ZERO', () {
      final pts = [
        for (var h = 0; h < 48; h++)
          HourlyPoint(DateTime(2026, 6, 27, h), 0.0),
      ];
      final ins = EnergyInsightsEngine.compute(pts, now: DateTime(2026, 6, 28, 23, 10));
      expect(ins.recommendations.map((r) => r.code), contains('ALL_ZERO'));
      expect(ins.dataQuality.zeroHoursShare, 1.0);
    });

    test('veille élevée => HIGH_STANDBY avec économie estimée', () {
      final pts = [
        for (var d = 0; d < 14; d++)
          for (var h = 0; h < 24; h++)
            HourlyPoint(DateTime(2026, 6, 1 + d, h), h <= 5 ? 0.30 : 0.35),
      ];
      final ins = EnergyInsightsEngine.compute(pts, now: DateTime(2026, 6, 14, 23, 5));
      final r = ins.recommendations.firstWhere((r) => r.code == 'HIGH_STANDBY');
      expect(r.estimatedSavingKwhMonth, closeTo(0.15 * 24 * 30, 1e-6));
      expect(ins.score.standby, 40); // pénalité plafonnée
    });

    test('dérive nocturne sur 3 nuits consécutives', () {
      final pts = <HourlyPoint>[];
      for (var d = 0; d < 21; d++) {
        for (var h = 0; h < 24; h++) {
          final drift = d >= 18 && h <= 5; // 3 dernières nuits
          pts.add(HourlyPoint(
              DateTime(2026, 6, 1 + d, h), drift ? 0.20 : (h <= 5 ? 0.05 : 0.2)));
        }
      }
      final ins = EnergyInsightsEngine.compute(pts, now: DateTime(2026, 6, 21, 23, 5));
      final drifts =
          ins.anomalies.where((a) => a.kind == AnomalyKind.nightDrift).toList();
      expect(drifts.length, 1);
      expect(drifts.single.hourStart, DateTime(2026, 6, 21));
    });

    test('tendance en hausse > 15 % => RISING_TREND', () {
      final pts = [
        for (var d = 0; d < 14; d++)
          for (var h = 0; h < 24; h++)
            HourlyPoint(DateTime(2026, 6, 1 + d, h), d < 7 ? 0.10 : 0.15),
      ];
      // Les deux semaines doivent précéder « aujourd'hui » (jours complets).
      final ins = EnergyInsightsEngine.compute(pts, now: DateTime(2026, 6, 15, 12, 5));
      expect(ins.trendPct, closeTo(50, 1e-6));
      expect(ins.recommendations.map((r) => r.code), contains('RISING_TREND'));
    });

    test('recommandations en anglais', () {
      final ins = EnergyInsightsEngine.compute(referenceVector(DateTime(2026, 6, 1)),
          now: DateTime(2026, 6, 28, 23, 30), lang: 'en');
      expect(ins.recommendations.first.title, isNot(contains('é')));
    });
  });

  group('Tarif FCFA par tranches', () {
    test('tranche sociale seule', () {
      expect(EnergyTariff.costFcfa(100), 100 * 50);
    });
    test('facturation progressive', () {
      // 110×50 + 290×79 + 100×94
      expect(EnergyTariff.costFcfa(500), 110 * 50 + 290 * 79 + 100 * 94);
      expect(EnergyTariff.costFcfa(900),
          110 * 50 + 290 * 79 + 400 * 94 + 100 * 99);
    });
    test('tarif propre au kit', () {
      expect(EnergyTariff.costFcfa(10, flatFcfaPerKwh: 120), 1200);
    });
    test('prix marginal', () {
      expect(EnergyTariff.marginalRate(50), 50);
      expect(EnergyTariff.marginalRate(450), 94);
    });
  });
}
