import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String registerNumber;
  final String role; // 'student' or 'admin'
  final String profileImageUrl;
  final bool isOnline;
  final String instagram;
  final String whatsapp;
  final String status; // 'active', 'blocked'
  final bool isBanned;
  final DateTime? lastSeen;
  final DateTime? dateOfBirth;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.registerNumber,
    this.role = 'student',
    this.profileImageUrl = '',
    this.isOnline = false,
    this.instagram = '',
    this.whatsapp = '',
    this.status = 'active',
    this.isBanned = false,
    this.lastSeen,
    this.dateOfBirth,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Student',
      registerNumber: data['registerNumber'] ?? '',
      role: data['role'] ?? 'student',
      profileImageUrl: data['profileImageUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
      instagram: data['instagram'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      status: data['status'] ?? 'active',
      isBanned: data['isBanned'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'registerNumber': registerNumber,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'instagram': instagram,
      'whatsapp': whatsapp,
      'status': status,
      'isBanned': isBanned,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
    };
  }
}
