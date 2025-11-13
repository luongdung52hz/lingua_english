// lib/presentation/screens/chat/chat_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/chat_controller.dart';
import '../../../resources/styles/colors.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUid;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.currentUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _previousMessageCount = 0;
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;

  late final String currentUid;
  String friendName = '';

  List<MessageModel> _messages = [];
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    currentUid = widget.currentUid.isNotEmpty
        ? widget.currentUid
        : FirebaseAuth.instance.currentUser?.uid ?? '';

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = Provider.of<ChatController>(context, listen: false);
      chatController.setCurrentRoom(widget.roomId);
      _loadFriendName();
      _startListeningMessages(chatController);
    });
  }

  void _startListeningMessages(ChatController chatController) {
    _messagesSubscription?.cancel();
    _messagesSubscription =
        chatController.getMessagesStream(widget.roomId).listen((newMessages) {
          _handleNewMessages(newMessages);
        }, onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tải tin nhắn: $error')),
            );
          }
        });
  }

  void _handleNewMessages(List<MessageModel> newMessages) {
    if (!mounted) return;

    final oldLength = _messages.length;
    final newLength = newMessages.length;
    final hasNewMessages = newLength > oldLength;

    setState(() {
      _messages = List<MessageModel>.from(newMessages);
      _previousMessageCount = newLength;
    });

    // Auto-scroll khi có tin mới và đang ở gần đầu
    if (hasNewMessages && _shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToTop(animate: true);
        }
      });
    }

    // Lần đầu load → scroll lên đầu
    if (oldLength == 0 && newLength > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToTop(animate: false);
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.userScrollDirection != ScrollDirection.idle) {
      _isUserScrolling = false;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted &&
            _scrollController.position.userScrollDirection ==
                ScrollDirection.idle) {
          setState(() {
            _isUserScrolling = true;
          });
        }
      });
    }

    final currentPixels = _scrollController.position.pixels;
    final isNearTop = currentPixels <= 100;

    if (_shouldAutoScroll != isNearTop) {
      setState(() {
        _shouldAutoScroll = isNearTop;
      });
    }
  }

  Future<void> _loadFriendName() async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      final room = ChatRoomModel.fromJson(roomData);
      final friendUid = room.participants.firstWhere((u) => u != currentUid);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);
        if (mounted) {
          setState(() {
            friendName = userModel.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          friendName = 'Người dùng';
        });
      }
    }
  }

  void _scrollToTop({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    const targetPosition = 0.0;

    if (animate) {
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          friendName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_messages.isEmpty)
                  const Center(
                    child: Text(
                      'Chưa có tin nhắn nào',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 16,
                      ),
                    ),
                  ),

                if (_messages.isNotEmpty)
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Tin mới ở trên
                    padding: const EdgeInsets.all(8).copyWith(top: 70),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderUid == currentUid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index == _messages.length - 1 ||
                                  (index < _messages.length - 1 &&
                                      _messages[index].sentAt.toDate().day !=
                                          _messages[index + 1].sentAt.toDate().day))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    _formatTime(msg.sentAt),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500]),
                                  ),
                                ),
                              Text(
                                msg.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Nút scroll lên đầu
                if (!_isUserScrolling && !_shouldAutoScroll)
                  Positioned(
                    top: 90,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        setState(() {
                          _shouldAutoScroll = true;
                          _isUserScrolling = false;
                        });
                        _scrollToTop(animate: true);
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.arrow_downward,
                          color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
          _buildInputBar(chatController),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatController chatController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(chatController),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _sendMessage(chatController),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage(ChatController chatController) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      chatController.sendMessage(text, currentUid);
      _messageController.clear();

      setState(() {
        _shouldAutoScroll = true;
        _isUserScrolling = false;
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToTop(animate: true);
        }
      });
    } catch (e) {
      _showError('Lỗi gửi tin nhắn: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}