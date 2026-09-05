import 'package:get/get.dart';
import '../../data/models/news_article_model.dart';
import '../../data/repositories/news_repository.dart';

class NewsController extends GetxController {
  NewsController({required NewsRepository repository})
    : _repository = repository;
  final NewsRepository _repository;
  final articles = <NewsArticle>[].obs;
  final isLoading = true.obs;
  final error = ''.obs;
  Future<void>? _request;

  @override
  void onInit() {
    super.onInit();
    fetchDailyNews();
  }

  Future<void> fetchDailyNews() =>
      _request ??= _fetch().whenComplete(() => _request = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    error.value = '';
    try {
      final result = await _repository.fetchDailyNews();
      if (!isClosed) articles.assignAll(result);
    } catch (_) {
      if (!isClosed) error.value = 'Không thể tải tin tức. Vui lòng thử lại.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> refresh() => fetchDailyNews();
}
