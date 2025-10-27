import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_appbar.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Chat"),
      body: const Center(child: Text("Danh sách bạn bè và nhóm học")),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
