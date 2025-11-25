class YoutubePlaylist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final int itemCount;

  YoutubePlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.itemCount,
  });

  factory YoutubePlaylist.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final mediumThumb = thumbnails['medium'] ?? {};
    return YoutubePlaylist(
      id: json['id'] ?? '',
      title: snippet['title'] ?? '',
      thumbnailUrl: mediumThumb['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      itemCount: json['contentDetails']?['itemCount'] ?? 0,
    );
  }
}