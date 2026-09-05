// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';

class ChatService {
  ChatService({required FirebaseFirestore firestore}) : _firestore = firestore;
  final FirebaseFirestore _firestore;

  // Gửi tin nhắn
  Future<void> sendMessage(
    String chatRoomId,
    String senderUid,
    String content,
  ) async {
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(); // Auto ID

    final message = MessageModel(
      id: messageRef.id,
      chatRoomId: chatRoomId,
      senderUid: senderUid,
      content: content,
      sentAt: Timestamp.now(),
    );

    final batch = _firestore.batch();
    batch.set(messageRef, message.toJson());

    // Cập nhật lastMessage cho room
    batch.update(_firestore.collection('chat_rooms').doc(chatRoomId), {
      'lastMessage': content,
      'lastMessageAt': Timestamp.now(),
    });
    await batch.commit();
  }

  // Stream tin nhắn cho room
  Stream<List<MessageModel>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()..['id'] = doc.id))
              .toList(),
        );
  }

  // Stream danh sách rooms của user
  Stream<List<ChatRoomModel>> getUserChatRooms(String uid) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoomModel.fromJson(doc.data()..['id'] = doc.id))
              .toList(),
        );
  }
}
