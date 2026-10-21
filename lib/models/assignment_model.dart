import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final DateTime dueDate;
  final bool isCompleted;
  final String priority; // 'Urgent', 'Medium', 'Low'

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 'Medium',
  });

  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: data['dueDate'] is Timestamp
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.parse(data['dueDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }
}
