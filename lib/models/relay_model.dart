class RelayModel {
  int? id;
  String? name;
  bool isActive;
  int amperage;
  bool ackReceived;

  RelayModel({
    this.id,
    this.name,
    this.isActive = false,
    required this.amperage,
    this.ackReceived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive ? 1 : 0,
      'amperage': amperage,
      'ackReceived': ackReceived ? 1 : 0,
    };
  }

  factory RelayModel.fromMap(Map<String, dynamic> map) {
    return RelayModel(
      id: map['id'],
      name: map['name'],
      isActive: map['isActive'] == 1,
      amperage: map['amperage'],
      ackReceived: (map['ackReceived'] ?? 0) == 1,
    );
  }
}
