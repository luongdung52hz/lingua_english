import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../resources/styles/colors.dart';  // Giả sử bạn có AppColors
import '../../controllers/youtube_controller.dart';

class YoutubeChannelsScreen extends StatelessWidget {
  const YoutubeChannelsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(YoutubeController());

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
        title: const Text('Video Học Tiếng Anh'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.channels.length,
        itemBuilder: (context, index) {
          final channel = controller.channels[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.subscriptions, color: Colors.red),
              title: Text(channel['name']!),
              subtitle: const Text('Xem video với phụ đề'),  // Thêm hint về sub
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                controller.changeChannel(channel['id']!);
                context.go('/youtube/channels/playlists');
              },
            ),
          );
        },
      )),
    );
  }
}