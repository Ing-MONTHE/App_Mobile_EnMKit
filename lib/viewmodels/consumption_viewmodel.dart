import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:enmkit/models/consumption_model.dart';


class ConsumptionViewModel extends ChangeNotifier {
  final ConsumptionRepository _repository;

  List<ConsumptionModel> _consumptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  ConsumptionViewModel(this._repository);

  // Getters
  List<ConsumptionModel> get consumptions => _consumptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger toutes les consommations
  Future<void> fetchConsumptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _consumptions = await _repository.getAllConsumptions();
    } catch (e) {
      _errorMessage = "Erreur lors du chargement : $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une consommation
  Future<void> addConsumption(ConsumptionModel consumption) async {
    try {
      await _repository.addConsumption(consumption);
      _consumptions.add(consumption);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de l’ajout : $e";
      notifyListeners();
    }
  }

  // Mettre à jour une consommation
  Future<void> updateConsumption(ConsumptionModel consumption) async {
    try {
      await _repository.updateConsumption(consumption);
      int index = _consumptions.indexWhere(
          (c) => c.timestamp == consumption.timestamp);
      if (index != -1) {
        _consumptions[index] = consumption;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Erreur lors de la mise à jour : $e";
      notifyListeners();
    }
  }

  // Supprimer une consommation
  Future<void> deleteConsumption(DateTime timestamp) async {
    try {
      await _repository.deleteConsumption(timestamp);
      _consumptions.removeWhere((c) => c.timestamp == timestamp);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de la suppression : $e";
      notifyListeners();
    }
  }

  // 🔹 Récupérer la dernière consommation
  ConsumptionModel? getLastConsumption() {
    if (_consumptions.isEmpty) return null;

    // Tri par timestamp pour être sûr d’avoir la plus récente
    _consumptions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _consumptions.first;
  }
}
