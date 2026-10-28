import 'package:flutter/material.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/repositories/kit_repository.dart';

class KitViewModel extends ChangeNotifier {
  final KitRepository _repository;

  // Liste des kits
  List<KitModel> _kits = [];
  List<KitModel> get kits => _kits;

  // Indicateur de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  KitViewModel(DBService dbService) : _repository = KitRepository(dbService) {
    fetchKits();
  }

  /// Charger tous les kits depuis la base de données
  Future<void> fetchKits() async {
    _isLoading = true;
    notifyListeners();

    _kits = await _repository.getKit();

    _isLoading = false;
    notifyListeners();
  }

  /// Ajouter un nouveau kit
  Future<void> addKit(KitModel kit) async {
    await _repository.addKit(kit);
    _kits.add(kit);
    notifyListeners();
  }

  /// Mettre à jour un kit existant
  Future<void> updateKit(KitModel kit) async {
    await _repository.updateKit(kit);
    final index = _kits.indexWhere((k) => k.kitNumber == kit.kitNumber);
    if (index != -1) {
      _kits[index] = kit;
      notifyListeners();
    }
  }

  /// Change le numéro GSM d'un kit (clé) + répercute sur les entités liées.
  Future<void> changeKitNumber(String oldNumber, KitModel updated) async {
    await _repository.changeKitNumber(oldNumber, updated);
    final index = _kits.indexWhere((k) => k.kitNumber == oldNumber);
    if (index != -1) {
      _kits[index] = updated;
      notifyListeners();
    }
  }

  /// Récupérer le numéro du kit
  Future<String?> getKitNumber() async {
    return await _repository.getKitNumber();
  }

  /// Supprimer le kit existant
  Future<void> clearKit() async {
    await _repository.clearKit();
    _kits.clear();
    notifyListeners();
  }

  /// Marque un kit comme « configuré » (config envoyée avec succès) → débloque
  /// le pilotage des lignes, et met à jour la vue.
  Future<void> markConfigSent(String kitNumber, {bool sent = true}) async {
    await _repository.markConfigSent(kitNumber, sent: sent);
    final i = _kits.indexWhere((k) => k.kitNumber == kitNumber);
    if (i != -1) {
      _kits[i].configSent = sent;
      notifyListeners();
    }
  }

  /// Kit par son numéro, ou null s'il n'est pas (ou plus) en mémoire.
  KitModel? kitByNumber(String? kitNumber) {
    if (kitNumber == null) return null;
    final i = _kits.indexWhere((k) => k.kitNumber == kitNumber);
    return i == -1 ? null : _kits[i];
  }

  /// Vrai si ce kit attend la validation finale de sa configuration (l'écho du
  /// kit a concordé, « Fin_config » n'est pas encore parti).
  bool isConfigAckPending(String? kitNumber) =>
      kitByNumber(kitNumber)?.configAckPending ?? false;

  /// Mémorise la trame envoyée au kit, en attente de son écho.
  Future<void> setPendingConfig(String kitNumber, String message) async {
    await _repository.setPendingConfig(kitNumber, message);
    final k = kitByNumber(kitNumber);
    if (k != null) {
      k.pendingConfigMsg = message;
      k.configAckPending = false;
      notifyListeners();
    }
  }

  /// L'écho du kit concorde : on passe en « attente de validation ».
  Future<void> markConfigAckPending(String kitNumber) async {
    await _repository.markConfigAckPending(kitNumber);
    final k = kitByNumber(kitNumber);
    if (k != null && !k.configAckPending) {
      k.configAckPending = true;
      notifyListeners();
    }
  }

  /// Configuration close : plus rien en attente, le kit devient « configuré ».
  Future<void> clearPendingConfig(String kitNumber) async {
    await _repository.clearPendingConfig(kitNumber);
    final k = kitByNumber(kitNumber);
    if (k != null) {
      k.pendingConfigMsg = null;
      k.configAckPending = false;
      k.configSent = true;
      notifyListeners();
    }
  }

  /// Supprimer UN kit (et toutes ses données rattachées) de la base et de la
  /// liste en mémoire. Sans effet si le kit n'a pas de numéro (clé absente).
  Future<void> deleteKit(KitModel kit) async {
    final number = kit.kitNumber;
    if (number == null || number.isEmpty) return;
    await _repository.deleteKit(number);
    _kits.removeWhere((k) => k.kitNumber == number);
    notifyListeners();
  }
}
