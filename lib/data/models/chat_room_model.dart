// lib/data/models/chat_room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id; // ID phòng chat (kết hợp UID1_UID2)
  final List<String> participants; // [uid1, uid2]
  final Timestamp lastMessageAt;
  final String lastMessage; // Tin nhắn cuối để hiển thị preview

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.lastMessageAt,
    required this.lastMessage,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessageAt: json['lastMessageAt'] ?? Timestamp.now(),
      lastMessage: json['lastMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participants': participants,
    'lastMessageAt': lastMessageAt,
    'lastMessage': lastMessage,
  };
}


