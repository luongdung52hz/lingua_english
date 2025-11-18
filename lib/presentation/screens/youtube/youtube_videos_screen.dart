import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/youtube_controller.dart';
import '../../widgets/info_card.dart';
import 'package:collection/collection.dart'; //

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
          final playlist = controller.playlists.firstWhereOrNull(
                  (p) => p.id == controller.selectedPlaylistId.value
          );

          if (playlist != null) {
            name = playlist.title;
          } else {
            final channel = controller.channels.firstWhereOrNull(
                    (c) => c['id'] == controller.selectedChannelId.value
            );
            if (channel != null) {
              name = channel['name'] as String? ?? 'Kênh';
            }
          }

          return Text('Videos từ $name');
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (controller.selectedPlaylistId.value.isNotEmpty) {
                controller.fetchVideosByPlaylist(controller.selectedPlaylistId.value);
              } else if (controller.selectedChannelId.value.isNotEmpty) {
                controller.fetchVideosByChannel(controller.selectedChannelId.value);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        print('DEBUG UI Videos: Obx rebuild - isLoading: ${controller.isLoading.value}, videos.length: ${controller.videos.length}');

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary,));
        }

        if (controller.videos.isEmpty) {
          print('DEBUG UI Videos: Showing "Không có video" - List empty');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Không có video', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        print('DEBUG UI Videos: Showing ListView with ${controller.videos.length} items');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical:12 ),
          itemCount: controller.videos.length,
          itemBuilder: (context, index) {
            final video = controller.videos[index];

            // Format date giống cũ
            final formattedDate = '${video.publishedAt.day}/${video.publishedAt.month}/${video.publishedAt.year}';
            final subtitleText = '${video.channelTitle} • $formattedDate';

            return InfoCard(
              title: video.title,
              subtitle: subtitleText,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  video.thumbnailUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.play_circle_outline, color: Colors.grey),
                  ),
                ),
              ),
              onTap: () {
                controller.setCurrentVideoIndex(index);
                print('DEBUG Videos: Tapped video at index $index - ${video.title}');

                context.push('/youtube/player/${video.id}', extra: video);
              },
              trailing: const Icon(
                Icons.play_arrow,
                color: Colors.grey,
                size: 20, // Giữ size phù hợp
              ),

            );
          },
        );
      }),
    );
  }
}