// Moteur d'analyse « IA hors-ligne » d'EnMKit — implémentation Dart PURE du
// contrat partagé (EnMKit_platform/docs/CONTRACT.md §6). Le backend Python
// implémente le même algorithme : toute divergence de résultat est un bug.
//
// Aucune dépendance Flutter ni base de données : entrée = série horaire
// (heure de début, kWh consommés pendant l'heure), sortie = [EnergyInsights].
//
// FUSEAU : les heures sont des heures locales « naïves » de Douala (UTC+1,
// sans heure d'été). Pour que l'arithmétique horaire ne soit jamais faussée
// par l'heure d'été éventuelle de la machine (tests sur un PC en Europe…),
// les calculs internes se font sur des DateTime UTC portant les MÊMES champs
// (année, mois, jour, heure) ; les résultats sont reconvertis en DateTime
// locaux naïfs à la sortie. Aucune conversion de fuseau n'est appliquée.

import 'dart:math' as math;

/// Un point de la série horaire d'entrée.
class HourlyPoint {
  const HourlyPoint(this.hourStart, this.kwh);
  final DateTime hourStart;
  final double kwh;
}

/// Tranche tarifaire : jusqu'à [upToKwh] kWh/mois (inclus), au prix
/// [fcfaPerKwh]. La dernière tranche a `upToKwh = double.infinity`.
class TariffTier {
  const TariffTier(this.upToKwh, this.fcfaPerKwh);
  final double upToKwh;
  final double fcfaPerKwh;
}

/// Calcul du coût en FCFA (contrat §6.8).
class EnergyTariff {
  /// Barème résidentiel par tranches mensuelles PAR DÉFAUT (valeurs du
  /// contrat, « à faire valider » avec ENEO) : 0–110 kWh : 50 ; 111–400 : 79 ;
  /// 401–800 : 94 ; > 800 : 99 FCFA/kWh. Facturation progressive : chaque
  /// tranche est payée à son propre prix.
  static const List<TariffTier> defaultTiers = [
    TariffTier(110, 50),
    TariffTier(400, 79),
    TariffTier(800, 94),
    TariffTier(double.infinity, 99),
  ];

  /// Coût mensuel en FCFA pour [monthKwh] kWh. Si [flatFcfaPerKwh] est
  /// fourni (tarif propre au kit), il s'applique à tout le volume.
  static double costFcfa(
    double monthKwh, {
    double? flatFcfaPerKwh,
    List<TariffTier> tiers = defaultTiers,
  }) {
    if (monthKwh <= 0) return 0;
    if (flatFcfaPerKwh != null) return monthKwh * flatFcfaPerKwh;
    var cost = 0.0;
    var prev = 0.0;
    for (final t in tiers) {
      final upper = math.min(monthKwh, t.upToKwh);
      if (upper > prev) cost += (upper - prev) * t.fcfaPerKwh;
      if (monthKwh <= t.upToKwh) break;
      prev = t.upToKwh;
    }
    return cost;
  }

  /// Prix du kWh « marginal » (celui de la tranche atteinte) — sert à
  /// chiffrer une économie : un kWh évité est un kWh de la tranche haute.
  static double marginalRate(
    double monthKwh, {
    double? flatFcfaPerKwh,
    List<TariffTier> tiers = defaultTiers,
  }) {
    if (flatFcfaPerKwh != null) return flatFcfaPerKwh;
    for (final t in tiers) {
      if (monthKwh <= t.upToKwh) return t.fcfaPerKwh;
    }
    return tiers.last.fcfaPerKwh;
  }
}

/// Plage consécutive d'heures manquantes : de [from] à [to] = début du
/// DERNIER créneau manquant (bornes INCLUSES), soit [hours] heures.
class DataGap {
  const DataGap(this.from, this.to, this.hours);
  final DateTime from;
  final DateTime to;
  final int hours;

  Map<String, dynamic> toJson() => {
        'from': _iso(from),
        'to': _iso(to),
        'hours': hours,
      };
}

class DataQuality {
  const DataQuality({
    required this.expectedHours,
    required this.receivedHours,
    required this.completeness,
    required this.gaps,
    required this.zeroHoursShare,
  });
  final int expectedHours;
  final int receivedHours;

  /// Part des heures attendues effectivement reçues (0..1).
  final double completeness;

  /// Trous de données (≥ 1 h), plus récents d'abord, 20 au maximum.
  final List<DataGap> gaps;

  /// Part des heures reçues valant exactement 0 kWh.
  final double zeroHoursShare;

  Map<String, dynamic> toJson() => {
        'expected_hours': expectedHours,
        'received_hours': receivedHours,
        'completeness': _r(completeness),
        'gaps': gaps.map((g) => g.toJson()).toList(),
        'zero_hours_share': _r(zeroHoursShare),
      };
}

/// Valeur typique d'une heure de la journée (médiane + dispersion robuste).
class ProfilePoint {
  const ProfilePoint(this.hour, this.median, this.mad, this.count);
  final int hour;
  final double median;

  /// Median Absolute Deviation : médiane des écarts absolus à la médiane.
  final double mad;

  /// Nombre de relevés ayant servi au calcul (0 = heure jamais reçue).
  final int count;

  Map<String, dynamic> toJson() =>
      {'hour': hour, 'median': _r(median), 'mad': _r(mad)};
}

class EnergyProfile {
  const EnergyProfile(this.weekday, this.weekend, this.global);
  final List<ProfilePoint> weekday;
  final List<ProfilePoint> weekend;
  final List<ProfilePoint> global;

  /// Profil applicable à une date : week-end (sam./dim.) ou jours ouvrés.
  List<ProfilePoint> forDate(DateTime d) =>
      (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
          ? weekend
          : weekday;

  /// Somme des médianes globales : consommation d'une « journée type ».
  double get typicalDayKwh => global.fold(0.0, (s, p) => s + p.median);

  Map<String, dynamic> toJson() => {
        'weekday': weekday.map((p) => p.toJson()).toList(),
        'weekend': weekend.map((p) => p.toJson()).toList(),
        'global': global.map((p) => p.toJson()).toList(),
      };
}

/// Type d'anomalie : pic isolé ou dérive nocturne persistante.
enum AnomalyKind { spike, nightDrift }

class EnergyAnomaly {
  const EnergyAnomaly({
    required this.hourStart,
    required this.kwh,
    required this.expectedKwh,
    required this.z,
    required this.kind,
  });
  final DateTime hourStart;
  final double kwh;
  final double expectedKwh;
  final double z;
  final AnomalyKind kind;

  Map<String, dynamic> toJson() => {
        'hour_start': _iso(hourStart),
        'kwh': _r(kwh),
        'expected_kwh': _r(expectedKwh),
        'z': _r(z, 2),
        'kind': kind == AnomalyKind.spike ? 'spike' : 'night_drift',
      };
}

class ForecastPoint {
  const ForecastPoint(this.hourStart, this.kwh);
  final DateTime hourStart;
  final double kwh;
  Map<String, dynamic> toJson() =>
      {'hour_start': _iso(hourStart), 'kwh': _r(kwh)};
}

class EnergyForecast {
  const EnergyForecast({
    required this.next24h,
    required this.todayKwh,
    required this.monthKwh,
    required this.monthCostFcfa,
  });
  final List<ForecastPoint> next24h;
  final double todayKwh;
  final double monthKwh;
  final double monthCostFcfa;

  Map<String, dynamic> toJson() => {
        'next_24h': next24h.map((p) => p.toJson()).toList(),
        'today_kwh': _r(todayKwh, 3),
        'month_kwh': _r(monthKwh, 2),
        'month_cost_fcfa': monthCostFcfa,
      };
}

class EnergyScore {
  const EnergyScore({
    required this.value,
    required this.grade,
    required this.standby,
    required this.peak,
    required this.trend,
    required this.anomalies,
  });

  /// Score 0–100 (100 = sobre et régulier).
  final double value;

  /// Note A (≥ 85) … E (< 40).
  final String grade;

  /// Pénalités appliquées (points retirés).
  final double standby;
  final double peak;
  final double trend;
  final double anomalies;

  Map<String, dynamic> toJson() => {
        'value': _r(value, 1),
        'grade': grade,
        'penalties': {
          'standby': _r(standby, 1),
          'peak': _r(peak, 1),
          'trend': _r(trend, 1),
          'anomalies': _r(anomalies, 1),
        },
      };

  static String gradeFor(double v) {
    if (v >= 85) return 'A';
    if (v >= 70) return 'B';
    if (v >= 55) return 'C';
    if (v >= 40) return 'D';
    return 'E';
  }
}

enum RecoSeverity { info, warning, critical }

class EnergyRecommendation {
  const EnergyRecommendation({
    required this.code,
    required this.severity,
    required this.title,
    required this.body,
    this.estimatedSavingKwhMonth,
    this.estimatedSavingFcfaMonth,
  });
  final String code;
  final RecoSeverity severity;
  final String title;
  final String body;
  final double? estimatedSavingKwhMonth;
  final double? estimatedSavingFcfaMonth;

  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity.name,
        'title': title,
        'body': body,
        'estimated_saving_kwh_month': _r(estimatedSavingKwhMonth, 1),
      };
}

/// Résultat complet de l'analyse (forme `Insights` du contrat §6).
class EnergyInsights {
  const EnergyInsights({
    required this.kitNumber,
    required this.generatedAt,
    required this.days,
    required this.dataQuality,
    required this.profile,
    required this.anomalies,
    required this.baseLoadKw,
    required this.baseLoadShare,
    required this.peakHour,
    required this.peakShare,
    required this.trendPct,
    required this.avgDailyKwh,
    required this.forecast,
    required this.score,
    required this.recommendations,
  });

  final String? kitNumber;
  final DateTime generatedAt;
  final int days;
  final DataQuality dataQuality;
  final EnergyProfile profile;
  final List<EnergyAnomaly> anomalies;
  final double baseLoadKw;
  final double baseLoadShare;
  final int? peakHour;
  final double peakShare;
  final double? trendPct;
  final double avgDailyKwh;
  final EnergyForecast forecast;
  final EnergyScore score;
  final List<EnergyRecommendation> recommendations;

  /// Vrai dès qu'au moins un relevé horaire a été reçu dans la fenêtre.
  bool get hasData => dataQuality.receivedHours > 0;

  List<EnergyAnomaly> get spikes =>
      anomalies.where((a) => a.kind == AnomalyKind.spike).toList();

  Map<String, dynamic> toJson() => {
        'kit_id': null,
        'kit_number': kitNumber,
        'generated_at': _isoFull(generatedAt),
        'days': days,
        'data_quality': dataQuality.toJson(),
        'profile': profile.toJson(),
        'anomalies': anomalies.map((a) => a.toJson()).toList(),
        'base_load_kw': _r(baseLoadKw),
        'base_load_share': _r(baseLoadShare),
        'peak_hour': peakHour,
        'peak_share': _r(peakShare),
        'trend_pct': _r(trendPct, 1),
        'avg_daily_kwh': _r(avgDailyKwh, 3),
        'forecast': forecast.toJson(),
        'score': score.toJson(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
      };
}

/// Le moteur lui-même : fonctions pures, déterministes (même entrée + même
/// [now] ⇒ même sortie). PARITÉ STRICTE avec le backend Python
/// (`EnMKit_platform/api/app/services/analytics.py`), dont les choix
/// d'interprétation du contrat sont repris à l'identique :
///  • relevés postérieurs au créneau courant (horloge du kit décalée) ignorés ;
///  • fenêtre : du jour `aujourd'hui − (days − 1)` 00:00 jusqu'à `now` ;
///  • `expected_hours` : du 1er jour reçu (00:00) jusqu'au dernier créneau
///    écoulé (`floor(now) − 1 h`) ou au dernier relevé s'il est plus récent ;
///  • `gaps[].to` = début du dernier créneau manquant (INCLUS) ;
///  • `avg_daily_kwh` = moyenne horaire des relevés reçus × 24 ;
///  • `peak_share` = Σ moyennes horaires 18..22 / Σ moyennes horaires 0..23 ;
///  • tendance : jours civils complets (< aujourd'hui) avec ≥ 18 h reçues,
///    ramenés à 24 h ; ≥ 4 jours valides par semaine, sinon null ;
///  • `night_drift` : moyenne nocturne (00–05 h, ≥ 3 relevés) > 2 × veille ET
///    ≥ veille + 0,05 sur ≥ 3 nuits consécutives ; une anomalie par série,
///    datée de la dernière nuit, qui doit tomber dans les 7 derniers jours ;
///  • `next_24h` : les 24 créneaux SUIVANT le créneau courant ;
///  • `month_kwh` = mois reçu + reste prévu d'aujourd'hui + moyenne × jours
///    restants ;
///  • `ALL_ZERO` : ≥ 12 relevés dans les 24 derniers créneaux, tous à 0.
class EnergyInsightsEngine {
  EnergyInsightsEngine._();

  // Seuils du contrat §6.
  static const double zThreshold = 3.5;
  static const double minSpikeDeltaKwh = 0.05;
  static const double madFloor = 0.01;
  static const int maxGaps = 20;
  static const int maxAnomalies = 50;
  static const int minProfilePoints = 3;

  /// Heures du créneau de pointe « 18–22 h » (heures de DÉBUT 18 à 22 incluses).
  static const int peakFromHour = 18;
  static const int peakToHour = 22;

  /// Heures nocturnes « 00–05 h » (heures de début 0 à 5 incluses).
  static const int nightToHour = 5;

  /// Une journée compte pour la tendance si ≥ 18 h sur 24 ont été reçues.
  static const int minHoursForDay = 18;

  static const Duration _h = Duration(hours: 1);

  /// Analyse la série [points] à l'instant [now] sur les [days] derniers jours.
  static EnergyInsights compute(
    List<HourlyPoint> points, {
    required DateTime now,
    int days = 28,
    String lang = 'fr',
    double? tariffFcfaPerKwh,
    String? kitNumber,
  }) {
    days = math.max(1, days);
    final currentSlot = DateTime.utc(now.year, now.month, now.day, now.hour);
    final today = DateTime.utc(now.year, now.month, now.day);
    final windowStart = _addDays(today, -(days - 1));
    final monthStart = DateTime.utc(today.year, today.month, 1);

    // Série complète dédoublonnée (dernier point gagne), créneaux futurs ignorés.
    final all = <DateTime, double>{};
    for (final p in points) {
      if (!p.kwh.isFinite || p.kwh < 0) continue;
      final u = _u(p.hourStart);
      if (!u.isAfter(currentSlot)) all[u] = p.kwh;
    }
    final keys = all.keys.toList()..sort();
    final series = <DateTime, double>{
      for (final k in keys)
        if (!k.isBefore(windowStart)) k: all[k]!,
    };

    // ---- 1. Qualité des données ---------------------------------------------
    final gaps = <DataGap>[];
    var expected = 0;
    var received = 0;
    var zeroShare = 0.0;
    if (series.isNotEmpty) {
      final firstKey = series.keys.first;
      final lastKey = series.keys.last;
      final first = DateTime.utc(firstKey.year, firstKey.month, firstKey.day);
      final prevSlot = currentSlot.subtract(_h);
      final end = lastKey.isAfter(prevSlot) ? lastKey : prevSlot;
      expected = end.difference(first).inHours + 1;
      received = series.length;
      zeroShare = series.values.where((v) => v == 0).length / received;
      DateTime? runStart;
      for (var slot = first; !slot.isAfter(end); slot = slot.add(_h)) {
        final missing = !series.containsKey(slot);
        if (missing && runStart == null) runStart = slot;
        if (!missing && runStart != null) {
          gaps.add(DataGap(_l(runStart), _l(slot.subtract(_h)),
              slot.difference(runStart).inHours));
          runStart = null;
        }
      }
      if (runStart != null) {
        gaps.add(DataGap(
            _l(runStart), _l(end), end.difference(runStart).inHours + 1));
      }
    }
    final recentGaps = gaps.reversed.take(maxGaps).toList();
    final completeness =
        expected == 0 ? 0.0 : math.min(1.0, received / expected);
    final quality = DataQuality(
      expectedHours: expected,
      receivedHours: received,
      completeness: completeness,
      gaps: recentGaps,
      zeroHoursShare: zeroShare,
    );

    // ---- 2. Profil type ------------------------------------------------------
    final byAll = List.generate(24, (_) => <double>[]);
    final byWd = List.generate(24, (_) => <double>[]);
    final byWe = List.generate(24, (_) => <double>[]);
    for (final e in series.entries) {
      byAll[e.key.hour].add(e.value);
      (_isWeekend(e.key) ? byWe : byWd)[e.key.hour].add(e.value);
    }
    ProfilePoint pp(int h, List<double> v) =>
        ProfilePoint(h, _median(v), _mad(v), v.length);
    final global = [for (var h = 0; h < 24; h++) pp(h, byAll[h])];
    final weekday = [
      for (var h = 0; h < 24; h++)
        byWd[h].length >= minProfilePoints ? pp(h, byWd[h]) : global[h]
    ];
    final weekend = [
      for (var h = 0; h < 24; h++)
        byWe[h].length >= minProfilePoints ? pp(h, byWe[h]) : global[h]
    ];
    final profile = EnergyProfile(weekday, weekend, global);

    // ---- 4. Veille / moyenne journalière -------------------------------------
    final nightVals = [
      for (final e in series.entries)
        if (e.key.hour <= nightToHour) e.value
    ];
    final baseLoad = nightVals.isEmpty ? 0.0 : _median(nightVals);
    final avgDaily = received == 0
        ? 0.0
        : series.values.fold(0.0, (s, v) => s + v) / received * 24;
    final baseShare =
        avgDaily > 0 ? math.min(1.0, baseLoad * 24 / avgDaily) : 0.0;

    // ---- 5. Pointe -----------------------------------------------------------
    int? peakHour;
    var peakShare = 0.0;
    if (series.isNotEmpty) {
      var best = global.first.median;
      peakHour = 0;
      for (final p in global) {
        if (p.median > best) {
          best = p.median;
          peakHour = p.hour;
        }
      }
      final means = <int, double>{
        for (var h = 0; h < 24; h++)
          if (byAll[h].isNotEmpty)
            h: byAll[h].fold(0.0, (s, v) => s + v) / byAll[h].length,
      };
      final total = means.values.fold(0.0, (s, v) => s + v);
      if (total > 0) {
        var pk = 0.0;
        for (var h = peakFromHour; h <= peakToHour; h++) {
          pk += means[h] ?? 0;
        }
        peakShare = pk / total;
      }
    }

    // ---- 3. Anomalies --------------------------------------------------------
    final last7Start = _addDays(today, -6);
    final anomalies = <EnergyAnomaly>[];
    for (final e in series.entries) {
      if (e.key.isBefore(last7Start)) continue;
      final p = profile.forDate(e.key)[e.key.hour];
      final z = 0.6745 * (e.value - p.median) / math.max(p.mad, madFloor);
      if (z > zThreshold && e.value - p.median >= minSpikeDeltaKwh) {
        anomalies.add(EnergyAnomaly(
          hourStart: _l(e.key),
          kwh: e.value,
          expectedKwh: p.median,
          z: z,
          kind: AnomalyKind.spike,
        ));
      }
    }
    if (nightVals.isNotEmpty) {
      anomalies.addAll(_nightDrift(series, baseLoad, _mad(nightVals), last7Start));
    }
    anomalies.sort((a, b) => b.hourStart.compareTo(a.hourStart));
    if (anomalies.length > maxAnomalies) {
      anomalies.removeRange(maxAnomalies, anomalies.length);
    }
    final spikes = anomalies.where((a) => a.kind == AnomalyKind.spike).length;
    final drifts = anomalies.length - spikes;

    // ---- 6. Tendance ---------------------------------------------------------
    double? weekMean(DateTime start) {
      final vals = <double>[];
      for (var i = 0; i < 7; i++) {
        final ds = _addDays(start, i);
        final hv = <double>[
          for (var k = 0; k < 24; k++)
            if (all.containsKey(ds.add(Duration(hours: k))))
              all[ds.add(Duration(hours: k))]!
        ];
        if (hv.length >= minHoursForDay) {
          vals.add(hv.fold(0.0, (s, v) => s + v) / hv.length * 24);
        }
      }
      return vals.length >= 4
          ? vals.fold(0.0, (s, v) => s + v) / vals.length
          : null;
    }

    final last7 = weekMean(_addDays(today, -7));
    final prev7 = weekMean(_addDays(today, -14));
    double? trend;
    if (last7 != null &&
        prev7 != null &&
        prev7 > 0 &&
        !_addDays(today, -14).isBefore(windowStart)) {
      trend = (last7 - prev7) / prev7 * 100;
    }

    // ---- 7. Prévision --------------------------------------------------------
    double typical(DateTime u) => profile.forDate(u)[u.hour].median;
    final next24 = [
      for (var k = 1; k <= 24; k++)
        ForecastPoint(_l(currentSlot.add(Duration(hours: k))),
            typical(currentSlot.add(Duration(hours: k))))
    ];
    final todayReceived = all.entries
        .where((e) => !e.key.isBefore(today))
        .fold(0.0, (s, e) => s + e.value);
    var todayForecast = todayReceived;
    if (series.isNotEmpty) {
      for (var k = 0; k < 24; k++) {
        final slot = today.add(Duration(hours: k));
        if (!all.containsKey(slot)) todayForecast += typical(slot);
      }
    }
    final monthToDate = all.entries
        .where((e) => !e.key.isBefore(monthStart))
        .fold(0.0, (s, e) => s + e.value);
    final daysInMonth = DateTime.utc(today.year, today.month + 1, 0).day;
    final remainingDays = daysInMonth - today.day;
    final monthKwh =
        monthToDate + (todayForecast - todayReceived) + avgDaily * remainingDays;
    final forecast = EnergyForecast(
      next24h: next24,
      todayKwh: todayForecast,
      monthKwh: monthKwh,
      monthCostFcfa: EnergyTariff.costFcfa(monthKwh,
              flatFcfaPerKwh: tariffFcfaPerKwh)
          .roundToDouble(),
    );

    // ---- 9. Score ------------------------------------------------------------
    final pStandby = math.min(40.0, baseShare * 100);
    final pPeak = math.min(20.0, math.max(0.0, peakShare - 0.35) * 100);
    final pTrend = math.min(20.0, math.max(0.0, trend ?? 0) / 2);
    final pAnom = math.min(20.0, 4.0 * anomalies.length);
    final scoreVal =
        math.max(0.0, 100.0 - pStandby - pPeak - pTrend - pAnom);
    final score = EnergyScore(
      value: scoreVal,
      grade: EnergyScore.gradeFor(scoreVal),
      standby: pStandby,
      peak: pPeak,
      trend: pTrend,
      anomalies: pAnom,
    );

    // ---- 10. Recommandations -------------------------------------------------
    final cut24 = currentSlot.subtract(const Duration(hours: 24));
    final last24 = [
      for (final e in all.entries)
        if (e.key.isAfter(cut24)) e.value
    ];
    final recos = _recommend(
      lang: lang,
      hasData: series.isNotEmpty,
      baseLoad: baseLoad,
      baseShare: baseShare,
      peakShare: peakShare,
      trend: trend,
      spikes: spikes,
      drifts: drifts,
      completeness: completeness,
      allZero24h: last24.length >= 12 && last24.every((v) => v == 0),
      score: scoreVal,
      avgDaily: avgDaily,
      marginalRate:
          EnergyTariff.marginalRate(monthKwh, flatFcfaPerKwh: tariffFcfaPerKwh),
    );

    return EnergyInsights(
      kitNumber: kitNumber,
      generatedAt: now,
      days: days,
      dataQuality: quality,
      profile: profile,
      anomalies: anomalies,
      baseLoadKw: baseLoad,
      baseLoadShare: baseShare,
      peakHour: peakHour,
      peakShare: peakShare,
      trendPct: trend,
      avgDailyKwh: avgDaily,
      forecast: forecast,
      score: score,
      recommendations: recos,
    );
  }

  /// Dérive nocturne (voir l'en-tête de la classe).
  static List<EnergyAnomaly> _nightDrift(Map<DateTime, double> series,
      double baseLoad, double nightMad, DateTime last7Start) {
    final perNight = <DateTime, List<double>>{};
    for (final e in series.entries) {
      if (e.key.hour > nightToHour) continue;
      perNight
          .putIfAbsent(DateTime.utc(e.key.year, e.key.month, e.key.day),
              () => <double>[])
          .add(e.value);
    }
    final exceed = <DateTime, double>{};
    perNight.forEach((d, vs) {
      if (vs.length < 3) return;
      final m = vs.fold(0.0, (s, v) => s + v) / vs.length;
      if (m > 2 * baseLoad && m - baseLoad >= minSpikeDeltaKwh) exceed[d] = m;
    });
    final out = <EnergyAnomaly>[];
    final days = exceed.keys.toList()..sort();
    var run = <DateTime>[];
    void flush() {
      if (run.length >= 3 && !run.last.isBefore(last7Start)) {
        final m = exceed[run.last]!;
        out.add(EnergyAnomaly(
          hourStart: _l(run.last),
          kwh: m,
          expectedKwh: baseLoad,
          z: 0.6745 * (m - baseLoad) / math.max(nightMad, madFloor),
          kind: AnomalyKind.nightDrift,
        ));
      }
    }

    for (final d in days) {
      if (run.isNotEmpty && d == _addDays(run.last, 1)) {
        run.add(d);
        continue;
      }
      flush();
      run = [d];
    }
    flush();
    return out;
  }

  static List<EnergyRecommendation> _recommend({
    required String lang,
    required bool hasData,
    required double baseLoad,
    required double baseShare,
    required double peakShare,
    required double? trend,
    required int spikes,
    required int drifts,
    required double completeness,
    required bool allZero24h,
    required double score,
    required double avgDaily,
    required double marginalRate,
  }) {
    final en = lang == 'en';
    final out = <EnergyRecommendation>[];
    String pct(double v) => '${(v * 100).round()} %';
    String kwh(double v) => v.toStringAsFixed(1);
    String fcfa(double v) => '${v.round()} FCFA';

    if (!hasData) {
      out.add(EnergyRecommendation(
        code: 'DATA_GAPS',
        severity: RecoSeverity.warning,
        title: en ? 'No data received' : 'Aucune donnée reçue',
        body: en
            ? 'No hourly reading over the period. Check that the kit is powered, '
                'that its SIM card has SMS credit and that this phone receives '
                'its SMS.'
            : 'Aucun relevé horaire sur la période. Vérifiez que le kit est '
                'alimenté, que sa carte SIM a du crédit SMS et que ce téléphone '
                'reçoit bien ses SMS.',
      ));
      return out;
    }
    if (allZero24h) {
      out.add(EnergyRecommendation(
        code: 'ALL_ZERO',
        severity: RecoSeverity.critical,
        title: en ? 'Zero consumption for 24 h' : 'Consommation nulle depuis 24 h',
        body: en
            ? 'Every hourly frame of the last 24 hours is 0 kWh. If appliances '
                'were running, the meter is not counting: check the pulse wiring '
                '(meter LED), the kit "imp/kWh" setting and the kit power supply.'
            : 'Toutes les trames horaires des dernières 24 h valent 0 kWh. Si des '
                'appareils ont fonctionné, le compteur ne compte pas : vérifiez le '
                'câblage des impulsions (LED du compteur), le réglage « imp/kWh » '
                'du kit et son alimentation.',
      ));
    }
    if (baseShare > 0.25) {
      final saving = (baseLoad - 0.5 * baseLoad) * 24 * 30;
      final watts = (baseLoad * 1000).round();
      out.add(EnergyRecommendation(
        code: 'HIGH_STANDBY',
        severity: baseShare > 0.5 ? RecoSeverity.critical : RecoSeverity.warning,
        title: en ? 'High standby consumption' : 'Consommation de veille élevée',
        body: en
            ? 'At night (00–05 h) about $watts W stay on permanently, i.e. '
                '${pct(baseShare)} of your daily energy. Unplug chargers, TV '
                'decoders and appliances on standby, use a switchable power strip. '
                'Halving this base load would save about ${kwh(saving)} kWh/month '
                '(≈ ${fcfa(saving * marginalRate)}).'
            : 'La nuit (00–05 h), environ $watts W restent consommés en '
                'permanence, soit ${pct(baseShare)} de l\'énergie du jour. '
                'Débranchez chargeurs, décodeurs TV et appareils en veille, '
                'utilisez une multiprise à interrupteur. Diviser cette veille par '
                'deux économiserait environ ${kwh(saving)} kWh/mois '
                '(≈ ${fcfa(saving * marginalRate)}).',
        estimatedSavingKwhMonth: saving,
        estimatedSavingFcfaMonth: saving * marginalRate,
      ));
    }
    if (peakShare > 0.45) {
      out.add(EnergyRecommendation(
        code: 'PEAK_HEAVY',
        severity: RecoSeverity.warning,
        title: en
            ? 'Consumption concentrated in the evening'
            : 'Consommation concentrée en soirée',
        body: en
            ? '${pct(peakShare)} of the energy is used between 18:00 and 23:00, '
                'the ENEO grid peak (voltage drops, load shedding). Shift ironing, '
                'pumping or laundry to the daytime and use LED bulbs for evening '
                'lighting.'
            : '${pct(peakShare)} de l\'énergie est consommée entre 18 h et 23 h, '
                'période de pointe du réseau ENEO (baisses de tension, '
                'délestages). Décalez repassage, pompage ou lessive en journée et '
                'utilisez des ampoules LED pour l\'éclairage du soir.',
      ));
    }
    if (trend != null && trend > 15) {
      out.add(EnergyRecommendation(
        code: 'RISING_TREND',
        severity: trend > 40 ? RecoSeverity.critical : RecoSeverity.warning,
        title: en ? 'Rising consumption' : 'Consommation en hausse',
        body: en
            ? 'Your average daily consumption last week rose by ${trend.round()} % '
                'compared with the week before. A new appliance, a fridge with a '
                'worn door seal or something left on may be the cause.'
            : 'Votre consommation journalière moyenne de la dernière semaine est '
                'en hausse de ${trend.round()} % par rapport à la semaine '
                'précédente. Un nouvel appareil, un réfrigérateur au joint usé ou '
                'un oubli d\'extinction peut en être la cause.',
      ));
    }
    if (spikes >= 1) {
      final driftFr = drifts > 0 ? ' Une dérive nocturne a aussi été détectée.' : '';
      final driftEn = drifts > 0 ? ' A night-time drift was also detected.' : '';
      out.add(EnergyRecommendation(
        code: 'ANOMALIES',
        severity: spikes >= 5 ? RecoSeverity.critical : RecoSeverity.warning,
        title: en ? 'Unusual consumption spikes' : 'Pics de consommation inhabituels',
        body: en
            ? '$spikes hour(s) in the last 7 days are well above your usual '
                'consumption at the same hour. Identify the appliance (iron, water '
                'heater, hot plate) and check it is not faulty.$driftEn'
            : '$spikes heure(s) des 7 derniers jours dépassent nettement votre '
                'consommation habituelle à la même heure. Identifiez l\'appareil '
                'en cause (fer à repasser, chauffe-eau, plaque électrique) et '
                'vérifiez qu\'il n\'est pas défectueux.$driftFr',
      ));
    }
    if (completeness < 0.8) {
      out.add(EnergyRecommendation(
        code: 'DATA_GAPS',
        severity: completeness < 0.5 ? RecoSeverity.warning : RecoSeverity.info,
        title: en ? 'Incomplete data' : 'Données incomplètes',
        body: en
            ? 'Only ${pct(completeness)} of the expected hours were received, so '
                'the analysis is less reliable. Check the GSM coverage, the SMS '
                'credit of the kit SIM card and that this phone receives its SMS.'
            : 'Seulement ${pct(completeness)} des heures attendues ont été reçues : '
                'l\'analyse est moins fiable. Vérifiez la couverture GSM, le '
                'crédit SMS de la carte SIM du kit et que ce téléphone reçoit bien '
                'ses SMS.',
      ));
    }
    if (score >= 85) {
      out.add(EnergyRecommendation(
        code: 'GOOD_JOB',
        severity: RecoSeverity.info,
        title: en ? 'Well done, efficient use!' : 'Bravo, usage efficace !',
        body: en
            ? 'Your efficiency score is ${score.round()}/100 with about '
                '${avgDaily.toStringAsFixed(2)} kWh per day. Keep the good habits: '
                'LED lighting, switching off what is not used, heavy uses spread '
                'across the day.'
            : 'Votre score d\'efficacité est de ${score.round()}/100 avec environ '
                '${avgDaily.toStringAsFixed(2)} kWh par jour. Gardez les bons '
                'réflexes : éclairage LED, extinction de ce qui ne sert pas, usages '
                'lourds étalés dans la journée.',
      ));
    }
    return out;
  }

  // ---- Statistiques robustes -----------------------------------------------

  static double _median(List<double> v) {
    if (v.isEmpty) return 0;
    final s = [...v]..sort();
    final n = s.length;
    return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
  }

  static double _mad(List<double> v) {
    if (v.isEmpty) return 0;
    final m = _median(v);
    return _median([for (final x in v) (x - m).abs()]);
  }

  /// Exposés pour les tests et l'UI (calculs « à la main » des TP).
  static double median(List<double> v) => _median(v);
  static double mad(List<double> v) => _mad(v);
}

// ---- Outils de date (UTC « porteur de champs », cf. en-tête) ----------------

DateTime _u(DateTime d) => DateTime.utc(d.year, d.month, d.day, d.hour);
DateTime _l(DateTime u) => DateTime(u.year, u.month, u.day, u.hour);
DateTime _addDays(DateTime u, int n) => DateTime.utc(u.year, u.month, u.day + n);
bool _isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

String _isoFull(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

/// Arrondi des sorties JSON, identique au backend (`_r`).
double? _r(double? x, [int n = 4]) {
  if (x == null) return null;
  final f = math.pow(10, n);
  return (x * f).round() / f;
}

String _iso(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:00:00';
}
