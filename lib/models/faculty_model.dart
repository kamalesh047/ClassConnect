import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyModel {
  final String id;
  final String name;
  final String designation;
  final String email;
  final String cabin;

  FacultyModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.email,
    required this.cabin,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'email': email,
      'cabin': cabin,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory FacultyModel.fromMap(Map<String, dynamic> map, String id) {
    return FacultyModel(
      id: id,
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      email: map['email'] ?? '',
      cabin: map['cabin'] ?? '',
    );
  }
}
