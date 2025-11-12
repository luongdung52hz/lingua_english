// lib/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import '../../data/datasources/remote/chat_service.dart';
import '../../data/models/chat_room_model.dart';

import '../../data/models/message_model.dart';
import 'base_controller.dart';

class ChatController extends BaseController {
  final ChatService _chatService = ChatService();
  List<MessageModel> _messages = [];
  List<ChatRoomModel> _chatRooms = [];
  String? _currentRoomId;

  List<MessageModel> get messages => _messages;
  List<ChatRoomModel> get chatRooms => _chatRooms;
  String? get currentRoomId => _currentRoomId;

  // Load rooms của user
  Stream<List<ChatRoomModel>> getUserChatRooms(String uid) {
    return _chatService.getUserChatRooms(uid);
  }

  // Load messages cho room cụ thể
  void setCurrentRoom(String roomId) {
    _currentRoomId = roomId;
    notifyListeners();
  }

  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _chatService.getMessagesStream(roomId);
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String content, String senderUid) async {
    if (_currentRoomId == null || content.isEmpty) return;
    setLoading(true);
    try {
      await _chatService.sendMessage(_currentRoomId!, senderUid, content);
      // Messages sẽ update qua stream, không cần manual refresh
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}