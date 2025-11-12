// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi tin nhắn
  Future<void> sendMessage(String chatRoomId, String senderUid, String content) async {
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

    await messageRef.set(message.toJson());

    // Cập nhật lastMessage cho room
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': content,
      'lastMessageAt': Timestamp.now(),
    });
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
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromJson(doc.data()..['id'] = doc.id))
        .toList());
  }

  // Stream danh sách rooms của user
  Stream<List<ChatRoomModel>> getUserChatRooms(String uid) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatRoomModel.fromJson(doc.data()..['id'] = doc.id))
        .toList());
  }
}