class ClassSession {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final String day; // "Monday", "Tuesday", etc.

  ClassSession({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.day,
  });

  factory ClassSession.fromMap(Map<String, dynamic> data, String id) {
    return ClassSession(
      id: id,
      subject: data['subject'] ?? '',
      teacher: data['teacher'] ?? '',
      room: data['room'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      day: data['day'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
      'day': day,
    };
  }
}
