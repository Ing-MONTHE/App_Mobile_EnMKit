class ConsumptionModel {
  double kwh;
  DateTime timestamp;

  ConsumptionModel({
    required this.kwh,
    required this.timestamp,
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'kwh': kwh,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Créer un objet depuis un Map SQLite
  factory ConsumptionModel.fromMap(Map<String, dynamic> map) {
    return ConsumptionModel(
      kwh: (map['kwh'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
