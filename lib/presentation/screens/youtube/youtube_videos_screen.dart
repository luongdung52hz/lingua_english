import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/controllers/youtube_controller.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/youtube_controller.dart';

class YoutubeVideosScreen extends StatelessWidget {
  const YoutubeVideosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YoutubeController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          String name = 'Kênh';
          // Ưu tiên tên playlist nếu có
          final playlist = controller.playlists.firstWhereOrNull((p) => p.id == controller.selectedPlaylistId.value);
          if (playlist != null) {
            name = playlist.title;
          } else {
            final channelName = controller.channels.firstWhereOrNull((c) => c['id'] == controller.selectedChannelId.value)?['name'] ?? 'Kênh';
            name = channelName;
          }
          return Text('Videos từ $name');
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Sử dụng fetchVideosByPlaylist nếu có selectedPlaylistId, fallback fetchVideosByChannel
              if (controller.selectedPlaylistId.value.isNotEmpty) {
                controller.fetchVideosByPlaylist(controller.selectedPlaylistId.value);
              } else {
                controller.fetchVideosByChannel(controller.selectedChannelId.value);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        print('DEBUG UI Videos: Obx rebuild - isLoading: ${controller.isLoading.value}, videos.length: ${controller.videos.length}');  // Log mỗi rebuild
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.videos.isEmpty) {
          print('DEBUG UI Videos: Showing "Không có video" - List empty');  // Log khi empty
          return const Center(child: Text('Không có video'));
        }
        print('DEBUG UI Videos: Showing ListView with ${controller.videos.length} items');  // Log khi có
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.videos.length,
          itemBuilder: (context, index) {
            final video = controller.videos[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(video.thumbnailUrl, width: 80, height: 60, fit: BoxFit.cover),
                ),
                title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${video.channelTitle} • ${video.publishedAt.day}/${video.publishedAt.month}'),
                    const Text('Có phụ đề', style: TextStyle(fontSize: 12, color: Colors.green)),  // Hint sub
                  ],
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  // Preload subtitles trước khi navigate
                  final subs = await controller.fetchSubtitles(video.id);
                  if (subs != null) video.subtitles = subs;
                  context.go('/youtube/channels/playlists/videos/player/${video.id}', extra: video);
                },
              ),
            );
          },
        );
      }),
    );
  }
}