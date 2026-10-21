import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';

class TimetableService {
  final CollectionReference timetableCollection = FirebaseFirestore.instance
      .collection('timetable');

  // Add a class session
  Future<void> addClassSession(ClassSession session) async {
    await timetableCollection.add(session.toMap());
  }

  // Get classes for a specific day
  Stream<List<ClassSession>> getClassesForDay(String day) {
    return timetableCollection
        .where('day', isEqualTo: day)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ClassSession.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Delete a class session
  Future<void> deleteClassSession(String id) async {
    return await timetableCollection.doc(id).delete();
  }
}
