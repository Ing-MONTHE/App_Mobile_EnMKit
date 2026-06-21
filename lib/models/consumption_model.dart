class ConsumptionModel {
  double kwh;
  DateTime timestamp;
  String? kitNumber;

  ConsumptionModel({
    required this.kwh,
    required this.timestamp,
    this.kitNumber,
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'kwh': kwh,
      'timestamp': timestamp.toIso8601String(),
      'kitNumber': kitNumber,
    };
  }

  // Créer un objet depuis un Map SQLite
  factory ConsumptionModel.fromMap(Map<String, dynamic> map) {
    return ConsumptionModel(
      kwh: (map['kwh'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      kitNumber: map['kitNumber'],
    );
  }
}
