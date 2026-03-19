class AllowedNumberModel {
  int? id; // auto-increment
  String phoneNumber;

  AllowedNumberModel({
    this.id,
    required this.phoneNumber,
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
    };
  }

  // Créer un objet depuis un Map SQLite
  factory AllowedNumberModel.fromMap(Map<String, dynamic> map) {
    return AllowedNumberModel(
      id: map['id'],
      phoneNumber: map['phoneNumber'],
    );
  }
}
