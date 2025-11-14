import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';  // Fallback
import 'package:youtube_caption_scraper/youtube_caption_scraper.dart';  // Import scraper
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
    print('DEBUG Service: Calling channels API: $uploadsUrl');  // Log URL
    final uploadsResponse = await http.get(Uri.parse(uploadsUrl));
    print('DEBUG Service: Channels response status: ${uploadsResponse.statusCode}, body preview: ${uploadsResponse.body.substring(0, 200)}...');  // Log status + preview (không full body để tránh dài)
    if (uploadsResponse.statusCode != 200) {
      throw Exception('Không thể fetch kênh: ${uploadsResponse.body}');
    }

    final uploadsData = json.decode(uploadsResponse.body);
    final items = uploadsData['items'] as List;
    print('DEBUG Service: Channels items count: ${items.length}');  // Log items channels
    if (items.isEmpty) {
      throw Exception('Channel ID không hợp lệ hoặc không tồn tại (totalResults: 0)');
    }
    final uploadsPlaylistId = items[0]['contentDetails']['relatedPlaylists']['uploads'];
    print('DEBUG Service: Got uploadsPlaylistId: $uploadsPlaylistId');  // Log playlist ID

    // Fetch videos từ playlist
    final videosUrl = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploadsPlaylistId&maxResults=$maxResults&key=$apiKey&order=date';
    print('DEBUG Service: Calling playlistItems API: $videosUrl');  // Log URL
    final videosResponse = await http.get(Uri.parse(videosUrl));
    print('DEBUG Service: PlaylistItems response status: ${videosResponse.statusCode}, body preview: ${videosResponse.body.substring(0, 200)}...');  // Log status + preview
    if (videosResponse.statusCode != 200) {
      throw Exception('Không thể fetch videos: ${videosResponse.body}');
    }

    final videosData = json.decode(videosResponse.body);
    final videoItems = videosData['items'] as List;
    print('DEBUG Service: Raw video items from API: ${videoItems.length} (totalResults: ${videosData['pageInfo']['totalResults']}');
    final parsedVideos = videoItems.map<YoutubeVideo>((item) {
      try {
        return YoutubeVideo.fromJson(item);  // Gọi model
      } catch (e) {
        print('DEBUG Service: Parse fail for item: $item, error: $e');  // Log nếu map fail
        rethrow;  // Rethrow để controller catch
      }
    }).toList();
    print('DEBUG Service: Parsed to ${parsedVideos.length} YoutubeVideo objects');  // Log sau parse
    return parsedVideos;
  }

  // ... (giữ nguyên import và fetchVideosByChannel)

  Future<List<YoutubePlaylist>> fetchPlaylistsByChannel(String channelId, {int maxResults = 50}) async {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (apiKey == null) throw Exception('Không tìm thấy API Key YouTube');

    final url = 'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&channelId=$channelId&maxResults=$maxResults&key=$apiKey';
    print('DEBUG Service: Calling playlists API: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Không thể fetch playlists: ${response.body}');

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
    if (response.statusCode != 200) throw Exception('Không thể fetch videos playlist: ${response.body}');

    final data = json.decode(response.body);
    final items = data['items'] as List;
    print('DEBUG Service: Raw videos in playlist: ${items.length}');
    return items.map<YoutubeVideo>((item) => YoutubeVideo.fromJson(item)).toList();
  }

// ... (giữ nguyên fetchSubtitles và helpers)

  Future<List<SubtitleTrack>?> fetchSubtitles(String videoId) async {
    print('DEBUG Service: Fetching subs with scraper for $videoId');
    try {
      final scraper = YouTubeCaptionScraper();
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';  // Full URL
      final captionTracks = await scraper.getCaptionTracks(videoUrl);  // Bước 1: Lấy tracks

      if (captionTracks.isEmpty) {
        print('DEBUG Service: No caption tracks found');
        return null;
      }

      print('DEBUG Service: Found ${captionTracks.length} caption tracks');

      final List<SubtitleTrack> tracks = [];
      for (final track in captionTracks) {
        print('DEBUG Service: Processing track ${track.languageCode}');

        try {
          // Bước 2: getSubtitles từ track
          final subtitles = await scraper.getSubtitles(track);

          // Fix: Null-safe map (kiểm tra subtitles != null và sub.text != null)
          final fullText = (subtitles ?? []).map((sub) => sub.text ?? '').join(' ');

          tracks.add(SubtitleTrack(
            languageCode: track.languageCode,
            url: '',  // Không cần
            isAutoGenerated: false,  // Default
            text: fullText.isNotEmpty ? fullText : null,
          ));
          print('DEBUG Service: Added track ${track.languageCode} with text length: ${fullText.length}');
        } catch (trackError) {
          print('DEBUG Service: Skip track ${track.languageCode} due to error: $trackError');
          continue;  // Skip track này, không fail toàn bộ
        }
      }
      print('DEBUG Service: Scraped ${tracks.length} tracks successfully');
      return tracks.isNotEmpty ? tracks : null;
    } catch (e) {
      print('DEBUG Service: Scraper error: $e');
      // Fallback: Thử youtube_explode_dart
      return await _fetchSubtitlesFallback(videoId);
    }
  }

  // Fallback method dùng youtube_explode_dart (nếu scraper fail)
  Future<List<SubtitleTrack>?> _fetchSubtitlesFallback(String videoId) async {
    print('DEBUG Service: Fallback to youtube_explode for $videoId');
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.closedCaptions.getManifest(videoId);
      final List<SubtitleTrack> tracks = [];
      for (final trackInfo in manifest.tracks) {
        final rawSrt = await _downloadSrt(trackInfo.url.toString());
        if (rawSrt != null) {
          final fullText = _parseSrtToText(rawSrt);
          tracks.add(SubtitleTrack(
            languageCode: trackInfo.language.code,
            url: trackInfo.url.toString(),
            isAutoGenerated: trackInfo.isAutoGenerated,
            text: fullText.isNotEmpty ? fullText : null,
          ));
        }
      }
      yt.close();
      return tracks.isNotEmpty ? tracks : null;
    } catch (e) {
      print('DEBUG Service: Fallback also failed: $e');
      yt.close();
      return null;
    }
  }

  // Helper: Download raw SRT từ URL
  Future<String?> _downloadSrt(String url) async {
    try {
      if (url.isEmpty) return null;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      print('Lỗi download SRT: $e');
    }
    return null;
  }

  // Helper: Parse SRT thành plain text (bỏ timestamp và số thứ tự)
  String _parseSrtToText(String srt) {
    return srt
        .split('\n\n')  // Split theo block caption
        .map((block) {
      final lines = block.split('\n');
      if (lines.length > 2) {
        // Lấy từ dòng 3 trở đi (sau số thứ tự và timestamp)
        return lines.sublist(2).join(' ');
      }
      return '';
    })
        .where((text) => text.isNotEmpty)
        .join(' ');  // Join tất cả caption bằng space
  }


  Future<String?> downloadSubtitleText(String url) async {
    // Giữ nguyên cho fallback (raw SRT)
    try {
      if (url.isEmpty) return null;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      print('Lỗi download subtitle: $e');
    }
    return null;
  }
}
