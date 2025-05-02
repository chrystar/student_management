// models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String matricNumber;
  final String? level; // Added level field
  final String department; // Added department field

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.matricNumber,
    this.level, // Optional for lecturers
    required this.department, // Added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'matricNumber': matricNumber,
      'level': level,
      'department': department, // Include in JSON output
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      matricNumber: map['matricNumber'],
      level: map['level'],
      department: map['department'], // Parse from JSON
    );
  }
}
