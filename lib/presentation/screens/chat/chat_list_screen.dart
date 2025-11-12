// lib/presentation/screens/chat/chat_list_screen.dart (Mới: Danh sách chat rooms)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import cho Firestore
import '../../../app/routes/route_names.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Tin Nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.go(Routes.chatFriends),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: chatController.getUserChatRooms(currentUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final friendUid = room.participants.firstWhere((u) => u != currentUid);

              // Future để load UserModel từ Firestore theo friendUid
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(friendUid).get(),
                builder: (context, userSnapshot) {
                  String friendName = 'Người dùng'; // Fallback
                  if (userSnapshot.connectionState == ConnectionState.done) {
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final userModel = UserModel.fromJson(userData);
                      friendName = userModel.name;
                    } else {
                      friendName = 'Người dùng không xác định';
                    }
                  }

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(friendName), // Sửa thành tên đối phương
                    subtitle: Text(room.lastMessage.isNotEmpty ? room.lastMessage : 'Chưa có tin nhắn'), // Preview tin nhắn cuối
                    onTap: () => context.go('/chat/room/${room.id}'),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),

    );
  }
}