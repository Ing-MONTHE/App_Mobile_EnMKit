import 'package:flutter/foundation.dart';
import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';

class AllowedNumberViewModel extends ChangeNotifier {
  final AllowedNumberRepository _repository;

  List<AllowedNumberModel> _allowedNumbers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AllowedNumberViewModel(this._repository) {
    // 👉 Charge les numéros dès l'initialisation
    fetchAllowedNumbers();
  }

  // Getters
  List<AllowedNumberModel> get allowedNumbers => _allowedNumbers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger tous les numéros
  Future<void> fetchAllowedNumbers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allowedNumbers = await _repository.getAllNumbers();
    } catch (e) {
      _errorMessage = "Erreur lors du chargement : $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajouter un numéro
  Future<void> addAllowedNumber(AllowedNumberModel number) async {
    try {
      final id = await _repository.addNumber(number);

      // 🔑 On récupère l'ID généré par SQLite et on l'affecte
      _allowedNumbers.add(AllowedNumberModel(
        phoneNumber: number.phoneNumber,
      ));

      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de l’ajout : $e";
      notifyListeners();
    }
  }

  /// Mettre à jour un numéro
  Future<void> updateAllowedNumber(AllowedNumberModel number) async {
    try {
      await _repository.updateNumber(number);
      int index = _allowedNumbers.indexWhere((n) => n.id == number.id);
      if (index != -1) {
        _allowedNumbers[index] = number;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Erreur lors de la mise à jour : $e";
      notifyListeners();
    }
  }

  /// Supprimer un numéro
  Future<void> deleteAllowedNumber(int id) async {
    try {
      await _repository.deleteNumber(id);
      _allowedNumbers.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erreur lors de la suppression : $e";
      notifyListeners();
    }
  }
}
