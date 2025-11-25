import 'package:get/get.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../data/models/youtube_playlists_model.dart';
import '../../data/models/youtube_video_model.dart';

class YoutubeController extends GetxController {
  static YoutubeController get instance => Get.find();

  var videos = <YoutubeVideo>[].obs;
  var playlists = <YoutubePlaylist>[].obs;
  var isLoading = false.obs;
  var selectedChannelId = ''.obs;
  var selectedPlaylistId = ''.obs;
  var currentVideoIndex = 0.obs;

  var videoPositions = <String, Duration>{}.obs;

  final YoutubeService _service = Get.put(YoutubeService());

  var autoPlayEnabled = true.obs;

  final channels = [

    {
      'name': 'BBC Learning English',
      'id': 'UCHaHD477h-FeBbVh9Sh7syA',
      'playlists': [
        {'id': 'PLcetZ6gSk96_zHuVg6Ecy2F7j4Aq4valQ', 'title': '6 Minute English'},
        {'id': 'PLcetZ6gSk968x0G5TK-FXGrDjqjm-tYmB', 'title': 'English In A Minute'},
      ],
    },
    {
      'name': 'TED-Ed',
      'id': 'UCsooa4yRKGN_zEE8iknghZA',
    },
    {
      'name': 'Family Guy',
      'id': 'UCzI57speLHzZgl2Qq-cqe9Q',
    },
    {
      'name': 'Extra',
      'id': 'UCqZfc196aqw1edr9IvIaWow',
      'playlists': [
        {'id': 'PLHss0Pf8TrW5um35ZMSYRCjUjEwEjXLPh', 'title': 'Extra English'},

      ],

    },

    {
      'name': 'Alex-Tiếng Anh',
      'id': 'UCOHC3mlHop6TRXl7i8o2AYQ',
    },
  ].obs;

  Future<void> fetchPlaylistsByChannel(String channelId, {int maxResults = 50}) async {
    isLoading.value = true;
    try {
      final channel = channels.firstWhere(
            (ch) => ch['id'] == channelId,
        orElse: () => {'name': 'Unknown', 'id': channelId},
      );

      if (channel.containsKey('playlists') &&
          channel['playlists'] != null &&
          (channel['playlists'] as List).isNotEmpty) {
        final manualPlaylists = (channel['playlists'] as List)
            .map<YoutubePlaylist>((pl) {
          final playlistJson = {
            'kind': 'youtube#playlist',
            'id': pl['id'] as String? ?? '',
            'snippet': {
              'publishedAt': DateTime.now().toIso8601String(),
              'channelId': channelId,
              'title': pl['title'] as String? ?? 'Manual Playlist',
              'description': '',
              'thumbnails': {
                'default': {'url': '', 'width': 120, 'height': 90},
                'medium': {'url': '', 'width': 320, 'height': 180},
                'high': {'url': '', 'width': 480, 'height': 360},
              },
              'channelTitle': channel['name'] as String? ?? 'Unknown Channel',
              'tags': <String>[],
              'defaultLanguage': '',
            },
            'contentDetails': {
              'itemCount': 0,
              'playlistId': pl['id'] as String? ?? '',
            },
          };
          return YoutubePlaylist.fromJson(playlistJson);
        }).toList();

        playlists.value = manualPlaylists;
      } else {
        playlists.value = await _service.fetchPlaylistsByChannel(channelId, maxResults: maxResults);
      }

      selectedChannelId.value = channelId;
      selectedPlaylistId.value = '';
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải playlists: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVideosByPlaylist(String playlistId, {int maxResults = 20}) async {
    isLoading.value = true;
    try {
      videos.value = await _service.fetchVideosByPlaylist(playlistId, maxResults: maxResults);
      selectedPlaylistId.value = playlistId;
      currentVideoIndex.value = 0;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải videos: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVideosByChannel(String channelId, {int maxResults = 20}) async {
    isLoading.value = true;
    try {
      videos.value = await _service.fetchVideosByChannel(channelId, maxResults: maxResults);
      selectedChannelId.value = channelId;
      currentVideoIndex.value = 0;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải videos: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void changeChannel(String channelId) {
    fetchPlaylistsByChannel(channelId);
  }

  void changePlaylist(String playlistId) {
    fetchVideosByPlaylist(playlistId);
  }

  YoutubeVideo? getNextVideo() {
    if (videos.isEmpty || currentVideoIndex.value >= videos.length - 1) {
      return null;
    }
    currentVideoIndex.value++;
    return videos[currentVideoIndex.value];
  }

  YoutubeVideo? getPreviousVideo() {
    if (videos.isEmpty || currentVideoIndex.value <= 0) {
      return null;
    }
    currentVideoIndex.value--;
    return videos[currentVideoIndex.value];
  }

  void setCurrentVideoIndex(int index) {
    if (index >= 0 && index < videos.length) {
      currentVideoIndex.value = index;
    }
  }

  List<YoutubeVideo> getRemainingVideos() {
    if (videos.isEmpty || currentVideoIndex.value >= videos.length - 1) {
      return [];
    }
    return videos.sublist(currentVideoIndex.value + 1);
  }

  void savePosition(String videoId, Duration position) {
    videoPositions[videoId] = position;
  }

  Duration? getSavedPosition(String videoId) {
    return videoPositions[videoId];
  }

  void clearPosition(String videoId) {
    videoPositions.remove(videoId);
  }

  void clearAllPositions() {
    videoPositions.clear();
  }

  void toggleAutoPlay() {
    autoPlayEnabled.value = !autoPlayEnabled.value;
  }
}