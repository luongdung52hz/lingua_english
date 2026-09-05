import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_article_model.dart';

class NewsRepository {
  NewsRepository({required http.Client client}) : _client = client;
  final http.Client _client;
  static final _rssSources = [
    {
      'url': 'https://learningenglish.voanews.com/api/zopqgoeuq',
      'name': 'VOA Learning English',
      'encoding': 'utf-8',
    },
    {
      'url': 'https://e.vnexpress.net/rss/news.rss',
      'name': 'VnExpress International',
      'encoding': 'utf-8',
    },
    {
      'url': 'https://www.rfa.org/english/rss2.xml',
      'name': 'Radio Free Asia',
      'encoding': 'utf-8',
    },
  ];

  Future<List<NewsArticle>> fetchDailyNews() async {
    Object? lastError;
    for (final source in _rssSources) {
      try {
        return await _fetchFromSource(source);
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Không thể tải tin tức: $lastError');
  }

  Future<List<NewsArticle>> _fetchFromSource(Map<String, String> source) async {
    final url = source['url']!;
    final encoding = source['encoding']!;

    final response = await _client
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
            'Accept-Encoding': 'gzip, deflate',
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Timeout fetching RSS'),
        );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    // Decode theo encoding
    String bodyText;
    try {
      if (encoding == 'utf-8') {
        bodyText = utf8.decode(response.bodyBytes);
      } else {
        bodyText = response.body;
      }
    } catch (e) {
      // Fallback nếu decode fail
      bodyText = response.body;
    }

    // Parse XML
    final document = xml.XmlDocument.parse(bodyText);
    final items = document.findAllElements('item');

    if (items.isEmpty) {
      throw Exception('No items found in RSS feed');
    }

    // Parse articles
    final articleList = items
        .map((item) {
          try {
            return NewsArticle.fromRssXml(item);
          } catch (e) {
            return null;
          }
        })
        .whereType<NewsArticle>() // Lọc null
        .where(
          (article) =>
              article.title.isNotEmpty &&
              article.url.isNotEmpty &&
              article.description.isNotEmpty,
        )
        .take(10) // Lấy 10 bài
        .toList();

    if (articleList.isEmpty) {
      throw Exception('No valid articles after filtering');
    }

    return articleList;
  }
}
