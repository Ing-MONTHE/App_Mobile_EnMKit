import 'package:enmkit/core/utils/sms_parser.dart';

/// Relevé HORAIRE d'un kit (table `hourly_consumptions`) : énergie consommée
/// pendant l'heure qui commence à [hourStart] (heure locale de Douala, naïve).
/// Une seule ligne par (kit, heure) : la dernière valeur reçue l'emporte.
class HourlyConsumptionModel {
  final String kitNumber;
  final DateTime hourStart;
  final double kwh;
  final DateTime receivedAt;

  const HourlyConsumptionModel({
    required this.kitNumber,
    required this.hourStart,
    required this.kwh,
    required this.receivedAt,
  });

  /// Clé `YYYY-MM-DDTHH:00:00` telle que stockée en base.
  String get hourKey => HourlyFrame.hourKeyOf(hourStart);

  Map<String, dynamic> toMap() => {
        'kitNumber': kitNumber,
        'hourStart': hourKey,
        'kWh': kwh,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory HourlyConsumptionModel.fromMap(Map<String, dynamic> map) {
    return HourlyConsumptionModel(
      kitNumber: (map['kitNumber'] as String?) ?? '',
      // Chaîne sans offset => DateTime LOCAL naïf (pas de conversion de fuseau).
      hourStart: DateTime.parse(map['hourStart'] as String),
      kwh: ((map['kWh'] ?? map['kwh']) as num).toDouble(),
      receivedAt: DateTime.tryParse((map['receivedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
