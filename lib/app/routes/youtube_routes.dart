import '../../presentation/controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';

import '../../presentation/screens/youtube/video_play_screen.dart';
import '../../presentation/screens/youtube/youtube_channel_screen.dart';
import '../../presentation/screens/youtube/youtube_playlists_video_screen.dart';
import '../../presentation/screens/youtube/youtube_videos_screen.dart';

List<RouteBase> youtubeRoutes(AuthController session) => [
  GoRoute(
    path: '/youtube/channels',
    builder: (context, state) => const YoutubeChannelsScreen(),
  ),
  GoRoute(
    path: '/youtube/playlists',
    builder: (context, state) => const YoutubePlaylistsScreen(),
  ),
  GoRoute(
    path: '/youtube/videos',
    builder: (context, state) => const YoutubeVideosScreen(),
  ),
  GoRoute(
    path: '/youtube/player/:videoId',
    builder: (context, state) {
      final videoId = state.pathParameters['videoId']!;
      return YoutubePlayerScreen(videoId: videoId);
    },
  ),
];
