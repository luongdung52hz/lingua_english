import 'package:get/get.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../data/models/youtube_playlists_model.dart';
import '../../data/models/youtube_video_model.dart';

class YoutubeController extends GetxController {
  static YoutubeController get instance => Get.find();

  var videos = <YoutubeVideo>[].obs;
  var playlists = <YoutubePlaylist>[].obs;  // Thêm list playlists reactive
  var isLoading = false.obs;
  var selectedChannelId = ''.obs;
  var selectedPlaylistId = ''.obs;  // Thêm selected playlist

  final YoutubeService _service = Get.put(YoutubeService());

  // Predefined channels (giữ nguyên)
  final channels = [
    {'name': 'LoL Esports', 'id': 'UCvqRdlKsE5Q8mf8YXbdIJLw'},
    {'name': 'BBC Learning English', 'id': 'UCHaHD477h-FeBbVh9Sh7syA'},
    {'name': 'TED-Ed', 'id': 'UCsooa4yRKGN_zEE8iknghZA'},
    {'name': 'Chill', 'id': 'UCLmns4BzCo5lFZAyQMPhxfg'},
  ].obs;

  // Thêm: Fetch playlists của channel
  Future<void> fetchPlaylistsByChannel(String channelId, {int maxResults = 50}) async {
    isLoading.value = true;
    try {
      playlists.value = await _service.fetchPlaylistsByChannel(channelId, maxResults: maxResults);
      selectedChannelId.value = channelId;
      selectedPlaylistId.value = '';  // Reset playlist
      print('DEBUG Controller: Fetched ${playlists.length} playlists');
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Sửa: Fetch videos từ playlist cụ thể
  Future<void> fetchVideosByPlaylist(String playlistId, {int maxResults = 20}) async {
    isLoading.value = true;
    try {
      videos.value = await _service.fetchVideosByPlaylist(playlistId, maxResults: maxResults);
      selectedPlaylistId.value = playlistId;
      print('DEBUG Controller: Fetched ${videos.length} videos from playlist $playlistId');
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Sửa: changeChannel → Fetch playlists thay vì videos
  void changeChannel(String channelId) {
    fetchPlaylistsByChannel(channelId);
  }

  // Thêm: changePlaylist
  void changePlaylist(String playlistId) {
    fetchVideosByPlaylist(playlistId);
  }
// Thêm vào YoutubeController:

  // Future<String?> fetchSubtitleTextForTrack(String videoId, String languageCode) async {
  //   return await _service.fetchSubtitleTextForTrack(videoId, languageCode);
  // }
  //
  // void clearSubtitleCache() {
  //   _service.clearSubtitleCache();
  // }
  Future<List<SubtitleTrack>?> fetchSubtitles(String videoId) async => await _service.fetchSubtitles(videoId);

  Future<String?> downloadSubtitleText(String url) async => await _service.downloadSubtitleText(url);

  void fetchVideosByChannel(String value) {}
}
