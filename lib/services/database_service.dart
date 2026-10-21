import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/faculty_model.dart';
import '../models/timetable_model.dart'; // Ensure this model exists and matches

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference notesCollection = FirebaseFirestore.instance
      .collection('notes');
  final CollectionReference announcementsCollection = FirebaseFirestore.instance
      .collection('announcements');
  final CollectionReference facultyCollection = FirebaseFirestore.instance
      .collection('faculty');
  final CollectionReference timetableCollection = FirebaseFirestore.instance
      .collection('timetable');
  final CollectionReference examsCollection = FirebaseFirestore.instance
      .collection('exams');

  // Create or update user data
  Future<void> saveUserData(UserModel user) async {
    await usersCollection.doc(user.uid).set(user.toMap());

    // Initialize default attendance for new students
    if (user.role == 'student') {
      await _initializeDefaultAttendance(user.uid);
    }
  }

  // Initialize default attendance (Mock subjects for now)
  Future<void> _initializeDefaultAttendance(String uid) async {
    final attendanceRef = usersCollection.doc(uid).collection('attendance');

    // Check if already exists to avoid overwriting
    final check = await attendanceRef.limit(1).get();
    if (check.docs.isNotEmpty) return;

    final subjects = [
      'Mathematics',
      'Physics',
      'Programming',
      'Electronics',
      'English',
    ];

    for (String subject in subjects) {
      await attendanceRef.doc(subject).set({
        'subject': subject,
        'totalClasses': 0,
        'attendedClasses': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get User Stream
  Stream<UserModel?> get userProfile {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get User Attendance Stream
  Stream<List<Map<String, dynamic>>> get attendance {
    return usersCollection.doc(uid).collection('attendance').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Add a note with more metadata
  Future<void> addNote(
    String title,
    String description,
    String url,
    String type,
    String uploaderName,
    String size,
  ) async {
    await notesCollection.add({
      'title': title,
      'description': description,
      'fileUrl': url,
      'type': type,
      'uploaderId': uid,
      'uploaderName': uploaderName,
      'fileSize': size,
      'likes': [], // List of user UIDs who liked
      'views': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Interaction: Like/Unlike a Note
  Future<void> toggleLikeNote(String noteId, String userUid) async {
    DocumentReference noteRef = notesCollection.doc(noteId);
    DocumentSnapshot doc = await noteRef.get();

    if (doc.exists) {
      List likes = (doc.data() as Map<String, dynamic>)['likes'] ?? [];
      if (likes.contains(userUid)) {
        await noteRef.update({
          'likes': FieldValue.arrayRemove([userUid]),
        });
      } else {
        await noteRef.update({
          'likes': FieldValue.arrayUnion([userUid]),
        });
      }
    }
  }

  // Interaction: Increment View Count
  Future<void> incrementNoteView(String noteId) async {
    await notesCollection.doc(noteId).update({
      'views': FieldValue.increment(1),
    });
  }

  // Get notes stream
  Stream<QuerySnapshot> get notes {
    return notesCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // Announcements
  Stream<List<AnnouncementModel>> get announcements {
    return announcementsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AnnouncementModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> addAnnouncement(
    String title,
    String content,
    String author,
  ) async {
    await announcementsCollection.add({
      'title': title,
      'content': content,
      'author': author,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Admin Functions ---

  // Get All Users (excluding current admin for management)
  Stream<List<UserModel>> get allUsers {
    return usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            return UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          })
          .where((u) => u.uid != uid)
          .toList();
    });
  }

  // Get All Students Stream
  Stream<List<UserModel>> get allStudents {
    return usersCollection.where('role', isEqualTo: 'student').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Update specific user role
  Future<void> updateRole(String userId, String newRole) async {
    await usersCollection.doc(userId).update({'role': newRole});
  }

  // Block/Ban User
  Future<void> blockUser(String userId) async {
    await usersCollection.doc(userId).update({
      'status': 'blocked',
      'isBanned': true,
    });
  }

  // Unblock/Active User
  Future<void> unblockUser(String userId) async {
    await usersCollection.doc(userId).update({
      'status': 'active',
      'isBanned': false,
    });
  }

  // Update Presence
  Future<void> updatePresence(bool isOnline) async {
    if (uid == null) return;
    await usersCollection.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Update Profile Details (Advanced)
  Future<void> updateProfile({
    String? name,
    String? imageUrl,
    String? instagram,
    String? whatsapp,
    String? bio,
    String? year,
    DateTime? dateOfBirth,
  }) async {
    if (uid == null) return;
    Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (imageUrl != null) updateData['profileImageUrl'] = imageUrl;
    if (instagram != null) updateData['instagram'] = instagram;
    if (whatsapp != null) updateData['whatsapp'] = whatsapp;
    if (bio != null) updateData['bio'] = bio;
    if (year != null) updateData['year'] = year;
    if (dateOfBirth != null) {
      updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    }

    if (updateData.isNotEmpty) {
      await usersCollection.doc(uid).update(updateData);
    }
  }

  // Get Student Presence Stream
  Stream<UserModel?> getPresence(String otherUid) {
    return usersCollection.doc(otherUid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update specific student attendance
  Future<void> updateStudentAttendance(
    String studentId,
    String subject,
    int attended,
    int total,
  ) async {
    await usersCollection
        .doc(studentId)
        .collection('attendance')
        .doc(subject) // Using subject name as ID to be simple
        .set({
          'subject': subject,
          'attendedClasses': attended,
          'totalClasses': total,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // Update FCM Token for push notifications
  Future<void> updateFcmToken(String? token) async {
    if (uid == null || token == null) return;
    await usersCollection.doc(uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- NEW: Faculty Management ---
  Stream<List<FacultyModel>> get faculty {
    return facultyCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FacultyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addFaculty(
    String name,
    String desig,
    String email,
    String cabin,
  ) async {
    await facultyCollection.add({
      'name': name,
      'designation': desig,
      'email': email,
      'cabin': cabin,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFaculty(String id) async {
    await facultyCollection.doc(id).delete();
  }

  // --- NEW: App-Wide Exam Settings ---
  // We use a single document 'upcoming' in 'exams' collection for simplicity
  Stream<Map<String, dynamic>?> get upcomingExam {
    return examsCollection.doc('upcoming').snapshots().map((doc) {
      return doc.data() as Map<String, dynamic>?;
    });
  }

  Future<void> updateUpcomingExam(String subject, DateTime date) async {
    await examsCollection.doc('upcoming').set({
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // --- NEW: Timetable Management (Admin) ---
  Future<void> addClassSession(ClassSession session) async {
    // Assuming TimetableService structure, adapt if different
    // Here we just add to a 'timetable' collection directly
    await timetableCollection.add(session.toMap());
  }

  Future<void> deleteClassSession(String id) async {
    await timetableCollection.doc(id).delete();
  }
}
