import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final CollectionReference assignmentsCollection = FirebaseFirestore.instance
      .collection('assignments');

  // Add assignment
  Future<void> addAssignment(Assignment assignment) async {
    await assignmentsCollection.add(assignment.toMap());
  }

  // Get assignments stream (ordered by due date)
  Stream<List<Assignment>> get assignments {
    return assignmentsCollection.orderBy('dueDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Assignment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Toggle completion status
  Future<void> toggleCompletion(String id, bool currentStatus) async {
    return await assignmentsCollection.doc(id).update({
      'isCompleted': !currentStatus,
    });
  }

  // Delete assignment
  Future<void> deleteAssignment(String id) async {
    return await assignmentsCollection.doc(id).delete();
  }

  // Update Due Date
  Future<void> updateDueDate(String id, DateTime newDate) async {
    return await assignmentsCollection.doc(id).update({
      'dueDate': Timestamp.fromDate(newDate),
    });
  }
}
