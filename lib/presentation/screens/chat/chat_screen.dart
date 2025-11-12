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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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

    // Sort ASC (cũ dưới, mới trên)
    if (oldLength == 0) {
      setState(() {
        _messages = List<MessageModel>.from(newMessages);
        _previousMessageCount = newLength;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToTop(animate: true);
        }
      });
      return;
    }

    if (newLength <= oldLength) {
      setState(() {
        _messages = List<MessageModel>.from(newMessages);
        _previousMessageCount = newLength;
      });
      return;
    }

    bool onlyAppended = true;
    for (int i = 0; i < oldLength; i++) {
      if (_messages[i].id != newMessages[i].id ||
          _messages[i].content != newMessages[i].content) {
        onlyAppended = false;
        break;
      }
    }

    if (onlyAppended) {
      final addedCount = newLength - oldLength;
      final animateCount = addedCount > 3 ? 1 : addedCount;
      for (int i = 0; i < addedCount; i++) {
        final newIndex = 0; // Thêm ở đầu danh sách
        _messages.insert(newIndex, newMessages[i]);
        if (i >= addedCount - animateCount) {
          _listKey.currentState!.insertItem(
            newIndex,
            duration: const Duration(milliseconds: 400),
          );
        }
      }

      _previousMessageCount = newLength;

      // Auto-scroll lên nếu đang ở gần đầu
      if (_shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollToTop(animate: false);
          }
        });
      }
    } else {
      setState(() {
        _messages = List<MessageModel>.from(newMessages);
        _previousMessageCount = newLength;
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
    final isNearTop = currentPixels <= 200;

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
      appBar: AppBar(
        title: Text(friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_messages.isEmpty)
                  const Center(child: Text('Chưa có tin nhắn nào')),

                if (_messages.isNotEmpty)
                  AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    reverse: true, // Tin mới ở trên
                    padding: const EdgeInsets.all(8).copyWith(top: 70),
                    physics: const AlwaysScrollableScrollPhysics(),
                    initialItemCount: _messages.length,
                    itemBuilder: (context, index, animation) {
                      final msg = _messages[index];
                      final isMe = msg.senderUid == currentUid;

                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                              MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue[600]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0 ||
                                    _messages[index].sentAt
                                        .toDate()
                                        .day !=
                                        _messages[index == 0
                                            ? index
                                            : index - 1]
                                            .sentAt
                                            .toDate()
                                            .day)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(bottom: 8),
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
                                    color: isMe
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (!_isUserScrolling && !_shouldAutoScroll)
                  Positioned(
                    top: 90,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        setState(() {
                          _shouldAutoScroll = false;
                          _isUserScrolling = false;
                        });
                        _scrollToTop(animate: false);
                      },
                      backgroundColor: Colors.blue,
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
      padding: const EdgeInsets.all(8.0),
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(chatController),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(chatController),
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
        _shouldAutoScroll = false;
        _isUserScrolling = true;
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToTop(animate: false);
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
