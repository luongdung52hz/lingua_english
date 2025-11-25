import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/youtube_controller.dart';
import '../../widgets/info_card.dart';
import 'package:collection/collection.dart';

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
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator(color: AppColors.primary,));
        if (controller.playlists.isEmpty) return const Center(child: Text('Không có playlist'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical:12 ),
          itemCount: controller.playlists.length,
          itemBuilder: (context, index) {
            final playlist = controller.playlists[index];
            final List<IconTextPair>? infoPairs = (playlist.itemCount != null && playlist.itemCount! > 0)
                ? [IconTextPair(Icons.video_library, '${playlist.itemCount} videos')]
                : null;
            return InfoCard(
              title: playlist.title,
              subtitle: playlist.channelTitle,
              infoPairs: infoPairs, // Sẽ null/empty → không render _InfoRow nếu không có
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  playlist.thumbnailUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.playlist_play, color: Colors.grey, size: 30),
                  ),
                ),
              ),
              onTap: () {
                controller.changePlaylist(playlist.id);  // Fetch videos của playlist
                context.push('/youtube/videos');  // Go to VideosScreen với playlist
              },
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            );
          },
        );
      }),
    );
  }
}