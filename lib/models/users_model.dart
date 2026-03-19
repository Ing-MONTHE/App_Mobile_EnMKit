class UserModel {
  final String phoneNumber;
  final String password; // hashé de préférence
  final bool isAdmin;
  final bool hasConnected;

  UserModel({
    required this.phoneNumber,
    required this.password,
    this.isAdmin = false,
    this.hasConnected = false,
  });

  // pour convertir en map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'password': password,
      'isAdmin': isAdmin ? 1 : 0,
      'hasConnected': hasConnected ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      phoneNumber: map['phoneNumber'],
      password: map['password'],
      isAdmin: map['isAdmin'] == 1,
      hasConnected: map['hasConnected'] == 1,
    );
  }
}
