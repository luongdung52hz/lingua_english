// presentation/controllers/news_controller.dart - Web-safe & Multiple RSS sources
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import '../../../data/models/news_article_model.dart';

class NewsController extends GetxController {
  final RxList<NewsArticle> articles = <NewsArticle>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Danh sách RSS feeds với priority
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

  @override
  void onInit() {
    super.onInit();
    fetchDailyNews();
  }

  Future<void> fetchDailyNews() async {
    isLoading.value = true;
    error.value = '';
    articles.clear();

    // Thử từng RSS source cho đến khi thành công
    for (final source in _rssSources) {
      try {
        final fetchedArticles = await _fetchFromSource(source);
        if (fetchedArticles.isNotEmpty) {
          articles.value = fetchedArticles;
          error.value = '';
          isLoading.value = false;
          return;
        }
      } catch (e) {
        print('Failed to fetch from ${source['name']}: $e');
        continue; // Thử source tiếp theo
      }
    }

    // Nếu tất cả sources đều fail
    error.value = 'Không thể tải tin tức từ tất cả nguồn';
    _loadFallbackData();
    isLoading.value = false;
  }

  Future<List<NewsArticle>> _fetchFromSource(Map<String, String> source) async {
    final url = source['url']!;
    final encoding = source['encoding']!;

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
      },
    ).timeout(
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
        print('Error parsing article: $e');
        return null;
      }
    })
        .whereType<NewsArticle>() // Lọc null
        .where((article) =>
    article.title.isNotEmpty &&
        article.url.isNotEmpty &&
        article.description.isNotEmpty)
        .take(10) // Lấy 10 bài
        .toList();

    if (articleList.isEmpty) {
      throw Exception('No valid articles after filtering');
    }

    return articleList;
  }

  void _loadFallbackData() {
    articles.value = [
      NewsArticle(
        title: 'English Learning: Daily Vocabulary',
        description: 'Learn new words every day to improve your English skills.',
        url: 'https://learningenglish.voanews.com',
        publishedAt: DateTime.now().toIso8601String(),
      ),
      NewsArticle(
        title: 'Grammar Tips for Beginners',
        description: 'Essential grammar rules explained in simple terms.',
        url: 'https://learningenglish.voanews.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Listening Practice: News Stories',
        description: 'Improve your listening skills with real news stories.',
        url: 'https://learningenglish.voanews.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Speaking Confidence Tips',
        description: 'Build confidence in speaking English naturally.',
        url: 'https://learningenglish.voanews.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Reading Comprehension Practice',
        description: 'Practice reading with level-appropriate articles.',
        url: 'https://learningenglish.voanews.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      ),
    ];
  }

  // Thêm method refresh manual
  Future<void> refresh() async {
    await fetchDailyNews();
  }
}