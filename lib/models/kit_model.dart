import 'relay_model.dart';

class KitModel {
  String? kitNumber;
  String? name;
  double? initialConsumption;
  int? pulseCount;

  /// Vrai si une configuration a déjà été envoyée AU KIT avec succès (accusé
  /// reçu). Le pilotage effectif des lignes n'est opérationnel qu'à partir de là.
  bool configSent;

  /// Trame de configuration exactement envoyée au kit, conservée tant que son
  /// écho n'a pas été reconnu. NULL = aucune configuration en attente d'écho.
  /// Persistée car l'écho du kit arrive souvent APPLICATION FERMÉE : c'est elle
  /// qui permet de reconnaître l'écho au redémarrage.
  String? pendingConfigMsg;

  /// Vrai quand l'écho du kit CONCORDE avec [pendingConfigMsg] : il ne manque
  /// plus que la validation de l'utilisateur pour clore la configuration.
  bool configAckPending;

  KitModel({
    this.kitNumber,
    this.name,
    this.initialConsumption = 0.0,
    this.pulseCount,
    this.configSent = false,
    this.pendingConfigMsg,
    this.configAckPending = false,
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
      'configured': configSent ? 1 : 0,
      'pendingConfigMsg': pendingConfigMsg,
      'configAckPending': configAckPending ? 1 : 0,
    };
  }

  factory KitModel.fromMap(Map<String, dynamic> map, {List<RelayModel> relays = const []}) {
    return KitModel(
      kitNumber: map['kitNumber'],
      name: map['name'],
      initialConsumption: (map['initialConsumption'] as num?)?.toDouble() ?? 0.0,
      pulseCount: map['pulseCount'],
      configSent: (map['configured'] ?? 0) == 1,
      pendingConfigMsg: map['pendingConfigMsg'] as String?,
      configAckPending: (map['configAckPending'] ?? 0) == 1,
    );
  }

  /// Méthode copyWith pour modifier uniquement certains champs
  KitModel copyWith({
    String? kitNumber,
    String? name,
    double? initialConsumption,
    int? pulseCount,
    bool? configSent,
    String? pendingConfigMsg,
    bool? configAckPending,
  }) {
    return KitModel(
      kitNumber: kitNumber ?? this.kitNumber,
      name: name ?? this.name,
      initialConsumption: initialConsumption ?? this.initialConsumption,
      pulseCount: pulseCount ?? this.pulseCount,
      configSent: configSent ?? this.configSent,
      pendingConfigMsg: pendingConfigMsg ?? this.pendingConfigMsg,
      configAckPending: configAckPending ?? this.configAckPending,
    );
  }
}
