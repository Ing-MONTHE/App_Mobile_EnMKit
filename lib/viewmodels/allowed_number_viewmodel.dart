import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:flutter/material.dart';

class AllowedNumberViewModel extends ChangeNotifier {
  final AllowedNumberRepository _repository;

  /// Kit ciblé par ce ViewModel (null = tous les numéros, compat. mono-kit).
  final String? kitNumber;

  List<AllowedNumberModel> _allowedNumbers = [];
  List<AllowedNumberModel> get allowedNumbers => _allowedNumbers;

  AllowedNumberViewModel(this._repository, {this.kitNumber}) {
    fetchAllowedNumbers();
  }

  Future<void> fetchAllowedNumbers() async {
    _allowedNumbers = await _repository.getAllNumbers(kitNumber: kitNumber);
    notifyListeners();
  }

  Future<void> addAllowedNumber(AllowedNumberModel number) async {
    // Rattache le numéro au kit ciblé puis persiste en base.
    number.kitNumber ??= kitNumber;
    await _repository.addNumber(number);
    await fetchAllowedNumbers();
  }

  Future<void> deleteAllowedNumber(int id) async {
    await _repository.deleteNumber(id);
    _allowedNumbers.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Définit les (au plus) DEUX numéros autorisés du kit en une fois : remplace
  /// l'ensemble par [first] et [second] (les valeurs vides sont ignorées).
  /// Le kit ne gère que deux numéros — d'où ces deux champs fixes côté UI.
  Future<void> setTwoNumbers(String? first, String? second) async {
    await _repository.clearAllowedNumbers(kitNumber: kitNumber);
    final values = [first, second]
        .map((e) => e?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    for (final v in values) {
      await _repository.addNumber(
        AllowedNumberModel(phoneNumber: v, kitNumber: kitNumber),
      );
    }
    await fetchAllowedNumbers();
  }
}
