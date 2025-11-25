class YoutubeVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;

  YoutubeVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
  //  this.subtitles,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    print('DEBUG Model: Parsing item preview: ${json['snippet']['title'] ?? 'No title'} (videoId: ${json['snippet']['resourceId']['videoId'] ?? 'No id'})');  // Log preview mỗi item
    try {
      final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
      final resourceId = snippet['resourceId'] as Map<String, dynamic>? ?? {};
      final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
      final mediumThumb = thumbnails['medium'] as Map<String, dynamic>? ?? {};

      final video = YoutubeVideo(
        id: resourceId['videoId'] as String? ?? '',
        title: snippet['title'] as String? ?? '',
        thumbnailUrl: mediumThumb['url'] as String? ?? '',
        channelTitle: snippet['channelTitle'] as String? ?? '',
        publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
        // subtitles...
      );

      print('DEBUG Model: Parsed success - Title: ${video.title}, ID: ${video.id}, Thumbnail: ${video.thumbnailUrl.isNotEmpty ? "OK" : "EMPTY"}');  // Log kết quả
      return video;
    } catch (e) {
      print('DEBUG Model: Parse error for full json: $json, error: $e');
      rethrow;
    }
  }
}

