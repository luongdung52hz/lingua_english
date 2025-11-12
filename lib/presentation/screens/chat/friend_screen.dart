// lib/presentation/screens/chat/friends_screen.dart (Cập nhật: Sử dụng GoRouter cho navigation)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/user_model.dart';
import '../../controllers/friend_controller.dart';

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
      appBar: AppBar(
        title: const Text('Tìm Kiếm Bạn Bè'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // GoRouter pop
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm theo tên ',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                if (query.length > 2) {
                  friendController.searchUsers(query);
                }
              },
            ),
          ),
          Expanded(
            child: friendController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : friendController.error != null
                ? Center(child: Text('Lỗi: ${friendController.error}'))
                : ListView.builder(
              itemCount: friendController.searchResults.length,
              itemBuilder: (context, index) {
                final user = friendController.searchResults[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await friendController.addFriend(currentUid, user);
                      final chatId = [currentUid, user.uid]..sort();
                      final roomId = chatId.join('_');
                      if (mounted) {
                        context.go('/chat/room/$roomId');
                      }
                    },
                    child: const Text('Thêm & Chat'),
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