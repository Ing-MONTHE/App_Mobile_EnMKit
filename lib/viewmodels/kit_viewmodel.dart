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
