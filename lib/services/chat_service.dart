import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final CollectionReference chatCollection = FirebaseFirestore.instance
      .collection('class_chat');

  // Send a message
  Future<void> sendMessage(
    String text,
    String senderId,
    String senderName,
    bool isSenderAdmin, {
    String? imageUrl,
  }) async {
    await chatCollection.add({
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isSenderAdmin': isSenderAdmin,
      'isDeleted': false,
      'isPinned': false,
    });
  }

  // Get message stream
  Stream<List<MessageModel>> get messages {
    return chatCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    await chatCollection.doc(messageId).update({'isDeleted': true});
  }

  // Pin message
  Future<void> pinMessage(String messageId) async {
    await chatCollection.doc(messageId).update({'isPinned': true});
  }

  // Unpin message
  Future<void> unpinMessage(String messageId) async {
    await chatCollection.doc(messageId).update({'isPinned': false});
  }
}
