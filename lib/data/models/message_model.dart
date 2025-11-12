// lib/data/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderUid;
  final String content;
  final Timestamp sentAt;
  final bool isRead; // Đã đọc chưa

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderUid,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      senderUid: json['senderUid'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] ?? Timestamp.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatRoomId': chatRoomId,
    'senderUid': senderUid,
    'content': content,
    'sentAt': sentAt,
    'isRead': isRead,
  };
}
