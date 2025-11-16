import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/youtube_playlists_model.dart';
import '../../models/youtube_video_model.dart';

class YoutubeService extends GetxService {
  static YoutubeService get to => Get.find();

  Future<List<YoutubeVideo>> fetchVideosByChannel(String channelId, {int maxResults = 20}) async {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (apiKey == null) {
      throw Exception('Không tìm thấy API Key YouTube');
    }

    // Lấy playlist ID từ channel uploads
    final uploadsUrl = 'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=$channelId&key=$apiKey';
    print('DEBUG Service: Calling channels API: $uploadsUrl');
    final uploadsResponse = await http.get(Uri.parse(uploadsUrl));
    print('DEBUG Service: Channels response status: ${uploadsResponse.statusCode}');

    if (uploadsResponse.statusCode != 200) {
      throw Exception('Không thể fetch kênh: ${uploadsResponse.body}');
    }

    final uploadsData = json.decode(uploadsResponse.body);
    final items = uploadsData['items'] as List;
    print('DEBUG Service: Channels items count: ${items.length}');

    if (items.isEmpty) {
      throw Exception('Channel ID không hợp lệ hoặc không tồn tại (totalResults: 0)');
    }

    final uploadsPlaylistId = items[0]['contentDetails']['relatedPlaylists']['uploads'];
    print('DEBUG Service: Got uploadsPlaylistId: $uploadsPlaylistId');

    // Fetch videos từ playlist
    final videosUrl = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploadsPlaylistId&maxResults=$maxResults&key=$apiKey&order=date';
    print('DEBUG Service: Calling playlistItems API: $videosUrl');
    final videosResponse = await http.get(Uri.parse(videosUrl));
    print('DEBUG Service: PlaylistItems response status: ${videosResponse.statusCode}');

    if (videosResponse.statusCode != 200) {
      throw Exception('Không thể fetch videos: ${videosResponse.body}');
    }

    final videosData = json.decode(videosResponse.body);
    final videoItems = videosData['items'] as List;
    print('DEBUG Service: Raw video items from API: ${videoItems.length}');

    final parsedVideos = videoItems.map<YoutubeVideo>((item) {
      try {
        return YoutubeVideo.fromJson(item);
      } catch (e) {
        print('DEBUG Service: Parse fail for item: $item, error: $e');
        rethrow;
      }
    }).toList();

    print('DEBUG Service: Parsed to ${parsedVideos.length} YoutubeVideo objects');
    return parsedVideos;
  }

  Future<List<YoutubePlaylist>> fetchPlaylistsByChannel(String channelId, {int maxResults = 50}) async {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (apiKey == null) throw Exception('Không tìm thấy API Key YouTube');

    final url = 'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&channelId=$channelId&maxResults=$maxResults&key=$apiKey';
    print('DEBUG Service: Calling playlists API: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Không thể fetch playlists: ${response.body}');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;
    print('DEBUG Service: Raw playlists: ${items.length}');
    return items.map<YoutubePlaylist>((item) => YoutubePlaylist.fromJson(item)).toList();
  }

  Future<List<YoutubeVideo>> fetchVideosByPlaylist(String playlistId, {int maxResults = 20}) async {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (apiKey == null) throw Exception('Không tìm thấy API Key YouTube');

    final url = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$playlistId&maxResults=$maxResults&key=$apiKey&order=date';
    print('DEBUG Service: Calling playlistItems API for playlist $playlistId: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Không thể fetch videos playlist: ${response.body}');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;
    print('DEBUG Service: Raw videos in playlist: ${items.length}');
    return items.map<YoutubeVideo>((item) => YoutubeVideo.fromJson(item)).toList();
  }
}