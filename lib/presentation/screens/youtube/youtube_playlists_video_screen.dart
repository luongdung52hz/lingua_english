import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/youtube_controller.dart';

class YoutubePlaylistsScreen extends StatelessWidget {
  const YoutubePlaylistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YoutubeController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final channelName = controller.channels.firstWhereOrNull((c) => c['id'] == controller.selectedChannelId.value)?['name'] ?? 'Kênh';
          return Text('Playlists từ $channelName');
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchPlaylistsByChannel(controller.selectedChannelId.value),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.playlists.isEmpty) return const Center(child: Text('Không có playlist'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.playlists.length,
          itemBuilder: (context, index) {
            final playlist = controller.playlists[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(playlist.thumbnailUrl, width: 80, height: 60, fit: BoxFit.cover),
                ),
                title: Text(playlist.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${playlist.channelTitle} • ${playlist.itemCount} videos'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  controller.changePlaylist(playlist.id);  // Fetch videos của playlist
                  context.go('/youtube/channels/playlists/videos');  // Go to VideosScreen với playlist
                },
              ),
            );
          },
        );
      }),
    );
  }
}