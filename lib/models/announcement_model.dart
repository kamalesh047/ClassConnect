import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime timestamp;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.timestamp,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> data, String id) {
    return AnnouncementModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? 'Admin',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
