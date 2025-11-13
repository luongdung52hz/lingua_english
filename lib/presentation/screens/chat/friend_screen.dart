// lib/presentation/screens/chat/friends_screen.dart (Cập nhật: Sử dụng GoRouter cho navigation)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/user_model.dart';
import '../../controllers/friend_controller.dart';
import '../../widgets/search_bar.dart'; // Import SearchBarWidget
import '../../../resources/styles/colors.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required String currentUid});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final friendController = Provider.of<FriendController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tìm Kiếm Bạn Bè',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(), // GoRouter pop
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (query) {
                if (query.length > 2) {
                  friendController.searchUsers(query);
                }
              },
              onSubmitted: (query) {
                if (query.length > 2) {
                  friendController.searchUsers(query);
                }
              },
              onClear: () {
                // Optional: Reset search results if needed
                //friendController.clearSearch();
              },
              hintText: 'Tìm theo tên',
              prefixIcon: Icons.search,
              clearIcon: Icons.clear,
              fillColor: Colors.grey[100],
              iconSize: 20,
              borderRadius: BorderRadius.circular(12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          Expanded(
            child: friendController.isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
                : friendController.error != null
                ? Center(
              child: Text(
                'Lỗi: ${friendController.error}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
                : friendController.searchResults.isEmpty
                ? Center(
              child: Text(
                'Không tìm thấy bạn bè nào',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: friendController.searchResults.length,
              itemBuilder: (context, index) {
                final user = friendController.searchResults[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await friendController.addFriend(currentUid, user);
                          final chatId = [currentUid, user.uid]..sort();
                          final roomId = chatId.join('_');
                          if (mounted) {
                            context.go('/chat/room/$roomId');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Thêm & Chat',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}