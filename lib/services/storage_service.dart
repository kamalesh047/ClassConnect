import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadFile({
    required PlatformFile file,
    required String path,
  }) async {
    try {
      final Reference ref = _storage.ref().child(path);

      UploadTask uploadTask;
      if (kIsWeb) {
        if (file.bytes == null) return null;
        uploadTask = ref.putData(file.bytes!);
      } else {
        if (file.path == null) return null;
        uploadTask = ref.putFile(File(file.path!));
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }
}
