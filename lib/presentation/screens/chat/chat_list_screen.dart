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
import '../../widgets/custom_sliver_appbar.dart'; // Thêm import cho CustomSliverAppBar
import '../../../resources/styles/colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Method để format thời gian (giả sử room có trường lastMessageTime là Timestamp)
  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView( // Thay body bằng CustomScrollView để hỗ trợ SliverAppBar
        slivers: [
          // Thêm CustomSliverAppBar thay thế AppBar thông thường
          CustomSliverAppBar(
            icon: Icons.message_outlined, // Icon phù hợp cho chat (có thể thay đổi)
            title: 'Tin Nhắn',
            subtitle: 'Danh sách phòng chat', // Thêm subtitle để phù hợp với thiết kế
            actions: [ // Chuyển actions từ AppBar cũ
              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white),
                onPressed: () => context.go(Routes.chatFriends),
              ),
            ],
            // Nếu cần bottom (ví dụ: TabBar), thêm ở đây; hiện tại không có
            expandedHeight: 90, // Giữ default hoặc điều chỉnh
          ),
          // SliverToBoxAdapter cho phần loading nếu cần, nhưng ở đây dùng StreamBuilder trực tiếp
          SliverToBoxAdapter(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: chatController.getUserChatRooms(currentUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 20, // Chiều cao tạm để tránh lỗi khi loading
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final rooms = snapshot.data!;
                if (rooms.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Chưa có phòng chat nào',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true, // Quan trọng cho Sliver: không chiếm full height
                  physics: const NeverScrollableScrollPhysics(), // Tắt scroll riêng, dùng scroll của CustomScrollView
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

                        // Giả sử ChatRoomModel có trường lastMessageTime: Timestamp (nếu không, cần thêm vào model)
                        //   final lastMessageTime = room.lastMessageTime ?? Timestamp.now(); // Fallback nếu null

                        return GestureDetector(
                          onTap: () => context.go('/chat/room/${room.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friendName, // Sửa thành tên đối phương
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        room.lastMessage.isNotEmpty ? room.lastMessage : 'Chưa có tin nhắn',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // trailing: Text(
                                //   _formatTime(lastMessageTime), // Thêm thời gian tin nhắn cuối vào trailing
                                //   style: const TextStyle(
                                //     fontSize: 12,
                                //     color: Colors.grey,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}