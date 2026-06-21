class RelayModel {
  int? id;
  String? name;
  bool isActive;
  int amperage;
  bool ackReceived;
  String? kitNumber;

  RelayModel({
    this.id,
    this.name,
    this.isActive = false,
    required this.amperage,
    this.ackReceived = false,
    this.kitNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive ? 1 : 0,
      'amperage': amperage,
      'ackReceived': ackReceived ? 1 : 0,
      'kitNumber': kitNumber,
    };
  }

  factory RelayModel.fromMap(Map<String, dynamic> map) {
    return RelayModel(
      id: map['id'],
      name: map['name'],
      isActive: map['isActive'] == 1,
      amperage: map['amperage'],
      ackReceived: (map['ackReceived'] ?? 0) == 1,
      kitNumber: map['kitNumber'],
    );
  }
}
