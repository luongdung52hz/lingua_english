import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/youtube_controller.dart';
import '../../widgets/info_card.dart';

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
        title: const Text('Video Học Tiếng Anh',style: AppTextStyles.headlinew,),
        backgroundColor: AppColors.primary,
       // foregroundColor: Colors.white,
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical:12 ),
        itemCount: controller.channels.length,
        itemBuilder: (context, index) {
          final channel = controller.channels[index];
          final channelName = channel['name'] as String;
          final channelId = channel['id'] as String;

          return InfoCard(
            title: channelName,
            subtitle: 'Truy cập kênh',
            onTap: () {
              controller.changeChannel(channelId);
              context.push('/youtube/playlists');
            },
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),

          );
        },
      )),
    );
  }
}