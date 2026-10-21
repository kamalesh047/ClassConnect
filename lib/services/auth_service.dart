import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';
import 'notification_service.dart';
import '../models/user_model.dart';
import '../data/student_list.dart' show classStudentList, checkIsAdmin;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _notificationService.init(result.user!.uid);
      }

      return result.user;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      rethrow;
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null; // User cancelled

      // 1. Check if email is in whitelist BEFORE proceeding
      final email = googleUser.email;
      Map<String, String>? authorizedRecord;

      final bool isAnAdmin = checkIsAdmin(email);

      if (isAnAdmin) {
        authorizedRecord = classStudentList.firstWhere(
          (student) => student['email']?.toLowerCase() == email.toLowerCase(),
          orElse: () => {
            'name': 'Administrator',
            'regNo': 'ADMIN',
            'email': email,
          },
        );
      } else {
        final found = classStudentList.firstWhere(
          (student) => student['email']?.toLowerCase() == email.toLowerCase(),
          orElse: () => {},
        );
        if (found.isNotEmpty) authorizedRecord = found;
      }

      if (authorizedRecord == null) {
        await GoogleSignIn().signOut(); // Force sign out from Google
        throw FirebaseAuthException(
          code: 'not-authorized',
          message:
              'Access Denied: This email ($email) is not in the class list.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        final db = DatabaseService(uid: user.uid);
        final existingDoc = await db.usersCollection.doc(user.uid).get();

        String role = checkIsAdmin(email) ? 'admin' : 'student';

        // If user already exists, preserve their role (unless they are the master admin)
        if (existingDoc.exists) {
          final data = existingDoc.data() as Map<String, dynamic>?;
          if (data != null && data['role'] != null && !checkIsAdmin(email)) {
            role = data['role'];
          }
        }

        final newUser = UserModel(
          uid: user.uid,
          email: email,
          name: authorizedRecord['name'] ?? 'User',
          registerNumber: authorizedRecord['regNo'] ?? 'Unknown',
          role: role,
        );

        // Save/Update user data
        await db.saveUserData(newUser);

        // Init Notifications
        await _notificationService.init(user.uid);
      }

      return user;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      rethrow;
    }
  }

  // Activate Account (Restricted Registration)
  Future<User?> activateAccount({
    required String email,
    required String password,
    DateTime? dateOfBirth,
  }) async {
    try {
      // 1. Check if student exists in our Class List
      Map<String, String>? authorizedRecord;

      final bool isAnAdmin = checkIsAdmin(email);

      if (isAnAdmin) {
        authorizedRecord = classStudentList.firstWhere(
          (student) => student['email']?.toLowerCase() == email.toLowerCase(),
          orElse: () => {
            'name': 'Administrator',
            'regNo': 'ADMIN',
            'email': email,
          },
        );
      } else {
        final found = classStudentList.firstWhere(
          (student) =>
              student['email']?.trim().toLowerCase() ==
              email.trim().toLowerCase(),
          orElse: () => {},
        );
        if (found.isNotEmpty) authorizedRecord = found;
      }

      if (authorizedRecord == null) {
        throw FirebaseAuthException(
          code: 'not-authorized',
          message: 'Access Denied: $email is not in the class list.',
        );
      }

      // 2. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 3. Automatically pull Name and RegNo from the Record
        final name = authorizedRecord['name'] ?? 'User';
        final regNo = authorizedRecord['regNo'] ?? 'Unknown';

        // Update Firebase Profile for "Hello, Name" to work immediately
        await user.updateDisplayName(name);

        final newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          registerNumber: regNo,
          role: checkIsAdmin(email) ? 'admin' : 'student',
          dateOfBirth: dateOfBirth,
        );

        // 4. Save to Database
        await DatabaseService().saveUserData(newUser);

        // Init Notifications
        await _notificationService.init(user.uid);
      }

      return user;
    } catch (e) {
      if (kDebugMode) print(e.toString());
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    final e = email.trim().toLowerCase();
    final bool isInList = classStudentList.any(
      (s) => s['email']?.toLowerCase() == e,
    );
    final bool isAnAdmin = checkIsAdmin(e);

    if (!isInList && !isAnAdmin) {
      throw FirebaseAuthException(
        code: 'not-authorized',
        message: 'Access Denied: This email is not in the class list.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
