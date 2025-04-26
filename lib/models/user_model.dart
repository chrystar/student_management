// models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String matricNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.matricNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'matricNumber': matricNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      matricNumber: map['matricNumber'],
    );
  }
}
