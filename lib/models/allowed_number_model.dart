class AllowedNumberModel {
  int? id; // auto-increment
  String phoneNumber;
  String? kitNumber;

  AllowedNumberModel({
    this.id,
    required this.phoneNumber,
    this.kitNumber,
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'kitNumber': kitNumber,
    };
  }

  // Créer un objet depuis un Map SQLite
  factory AllowedNumberModel.fromMap(Map<String, dynamic> map) {
    return AllowedNumberModel(
      id: map['id'],
      phoneNumber: map['phoneNumber'],
      kitNumber: map['kitNumber'],
    );
  }
}
