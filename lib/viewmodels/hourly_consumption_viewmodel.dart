import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/models/hourly_consumption_model.dart';
import 'package:enmkit/repositories/hourly_consumption_repository.dart';
import 'package:flutter/foundation.dart';

/// Relevés horaires d'UN kit + analyse IA hors-ligne dérivée (contrat §6).
///
/// L'analyse est recalculée paresseusement (à la demande de l'UI) et mise en
/// cache tant que les données et la langue ne changent pas.
class HourlyConsumptionViewModel extends ChangeNotifier {
  HourlyConsumptionViewModel(
    this._repo, {
    required this.kitNumber,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HourlyConsumptionRepository _repo;
  final String? kitNumber;
  final DateTime Function() _clock;

  /// Profondeur chargée : 28 jours d'analyse + le début du mois en cours.
  static const int loadDays = 62;

  List<HourlyConsumptionModel> _points = const [];
  bool _isLoading = false;
  bool _loadedOnce = false;
  String? _error;

  EnergyInsights? _cache;
  String? _cacheLang;

  List<HourlyConsumptionModel> get points => _points;
  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  bool get hasData => _points.isNotEmpty;
  DateTime now() => _clock();

  /// Dernier relevé horaire reçu (le plus récent), ou null.
  HourlyConsumptionModel? get latest => _points.isEmpty ? null : _points.last;

  Future<void> load() async {
    final k = kitNumber;
    if (k == null || k.isEmpty) {
      _loadedOnce = true;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final from = _clock().subtract(const Duration(days: loadDays));
      _points = await _repo.getHourly(k, from: from);
      _cache = null;
    } catch (e) {
      _error = '$e';
    } finally {
      _isLoading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Chemin TEMPS RÉEL : persiste les trames d'un SMS reçu (upsert idempotent)
  /// puis recharge. Le drain natif fait la même persistance de son côté.
  Future<void> ingestFrames(List<HourlyFrame> frames, {DateTime? at}) async {
    final k = kitNumber;
    if (k == null || k.isEmpty || frames.isEmpty) return;
    try {
      await _repo.upsertFrames(k, frames, receivedAt: at);
    } catch (_) {
      // Ne jamais planter la réception d'un SMS sur la persistance.
    }
    await load();
  }

  /// Analyse IA (cache par langue). [lang] : 'fr' | 'en'.
  EnergyInsights insights(String lang) {
    final c = _cache;
    if (c != null && _cacheLang == lang) return c;
    final res = EnergyInsightsEngine.compute(
      [for (final p in _points) HourlyPoint(p.hourStart, p.kwh)],
      now: _clock(),
      lang: lang,
      kitNumber: kitNumber,
    );
    _cache = res;
    _cacheLang = lang;
    return res;
  }

  /// Énergie (kWh) consommée entre [from] et [to] (heures de début incluses
  /// dans [from, to[ ) + nombre d'heures attendues / reçues. Sert aux TP
  /// « Scénario A / B ».
  ({double kwh, int expectedHours, int receivedHours}) energyBetween(
      DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day, from.hour);
    final b = DateTime(to.year, to.month, to.day, to.hour);
    var kwh = 0.0;
    var n = 0;
    for (final p in _points) {
      if (!p.hourStart.isBefore(a) && p.hourStart.isBefore(b)) {
        kwh += p.kwh;
        n++;
      }
    }
    final expected = b.isAfter(a) ? b.difference(a).inHours : 0;
    return (kwh: kwh, expectedHours: expected, receivedHours: n);
  }
}
