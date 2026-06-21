import 'relay_model.dart';

class KitModel {
  String? kitNumber;
  String? name;
  double? initialConsumption;
  int? pulseCount;

  KitModel({
    this.kitNumber,
    this.name,
    this.initialConsumption = 0.0,
    this.pulseCount,
  });

  /// Nom lisible du kit (repli sur le numéro si aucun nom n'est défini).
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (kitNumber != null && kitNumber!.isNotEmpty) return kitNumber!;
    return 'Kit sans nom';
  }

  /// Un kit est "configuré" dès qu'il possède un numéro GSM.
  bool get isConfigured => kitNumber != null && kitNumber!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'kitNumber': kitNumber,
      'name': name,
      'initialConsumption': initialConsumption,
      'pulseCount': pulseCount,
    };
  }

  factory KitModel.fromMap(Map<String, dynamic> map, {List<RelayModel> relays = const []}) {
    return KitModel(
      kitNumber: map['kitNumber'],
      name: map['name'],
      initialConsumption: (map['initialConsumption'] as num?)?.toDouble() ?? 0.0,
      pulseCount: map['pulseCount'],
    );
  }

  /// Méthode copyWith pour modifier uniquement certains champs
  KitModel copyWith({
    String? kitNumber,
    String? name,
    double? initialConsumption,
    int? pulseCount,
  }) {
    return KitModel(
      kitNumber: kitNumber ?? this.kitNumber,
      name: name ?? this.name,
      initialConsumption: initialConsumption ?? this.initialConsumption,
      pulseCount: pulseCount ?? this.pulseCount,
    );
  }
}
