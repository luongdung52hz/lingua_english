import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../data/datasources/remote/translation_service.dart';
import '../../data/models/flashcard_model.dart';
import '../../data/repositories/flashcard_repository.dart';

class FlashcardController extends GetxController {
  final TranslationService _translationService = TranslationService(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');
  final FlashcardRepository _repository = FlashcardRepository();

  // Observable states
  final flashcards = <Flashcard>[].obs;
  final folders = <FlashcardFolder>[].obs;
  final isLoading = false.obs;
  final isTranslating = false.obs;
  final statistics = <String, int>{}.obs;
  final currentFolderId = 'default'.obs;
  final hasUnmemorized = false.obs;

  StreamSubscription<List<Flashcard>>? _flashcardSubscription;
  StreamSubscription<List<FlashcardFolder>>? _folderSubscription;
  Timer? _searchDebounce;


  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  @override
  void onClose() {
    _flashcardSubscription?.cancel();
    _folderSubscription?.cancel();
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> _initializeApp() async {
    try {
      await _repository.initializeDefaultFolder();
      loadFolders();
      loadFlashcards();
      await loadStatistics();
    } catch (e) {
      _showError('Không thể khởi tạo ứng dụng', e);
    }
  }

  void _updateHasUnmemorized() {
    hasUnmemorized.value = flashcards.any((f) => !f.isMemorized);
  }

  void loadFlashcards() {
    _flashcardSubscription?.cancel();
    _flashcardSubscription = _repository.getFlashcards().listen(
          (cards) {
        flashcards.value = cards;
        _updateHasUnmemorized();
        loadStatistics();
      },
      onError: (e) => _showError('Không thể tải flashcards', e),
    );
  }

  void loadFlashcardsByFolder(String folderId) {
    _flashcardSubscription?.cancel();
    currentFolderId.value = folderId;

    if (folderId == 'default') {
      loadFlashcards();
    } else {
      _flashcardSubscription = _repository.getFlashcardsByFolder(folderId).listen(
            (cards) {
          flashcards.value = cards;
          _updateHasUnmemorized();
          loadStatisticsByFolder(folderId);
        },
        onError: (e) => _showError('Không thể tải flashcards', e),
      );
    }
  }

  void loadFlashcardsToReview({String? folderId}) {
    _flashcardSubscription?.cancel();

    final stream = folderId != null && folderId != 'default'
        ? _repository.getFlashcardsToReviewByFolder(folderId)
        : _repository.getFlashcardsToReview();

    _flashcardSubscription = stream.listen(
          (cards) {
        flashcards.value = cards;
        _updateHasUnmemorized();
      },
      onError: (e) => _showError('Không thể tải flashcards cần học', e),
    );
  }

  void searchFlashcards(String query) {
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      if (currentFolderId.value == 'default') {
        loadFlashcards();
      } else {
        loadFlashcardsByFolder(currentFolderId.value);
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _flashcardSubscription?.cancel();
      _flashcardSubscription = _repository.searchFlashcards(query).listen(
            (cards) {
          if (currentFolderId.value != 'default') {
            flashcards.value = cards
                .where((c) => c.folderId == currentFolderId.value)
                .toList();
          } else {
            flashcards.value = cards;
          }
          _updateHasUnmemorized();
        },
        onError: (e) => _showError('Không thể tìm kiếm', e),
      );
    });
  }

  Future<Flashcard?> createFlashcardFromText(
      String inputText, {
        required TranslationDirection direction, //  NEW: Bắt buộc chọn hướng dịch
        String? folderId,
      }) async {
    if (inputText.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập từ cần dịch', snackPosition: SnackPosition.BOTTOM);
      return null;
    }

    try {
      isTranslating.value = true;
      print('🔍 [CREATE] Starting translation for input: "$inputText"');
      print('🌐 [CREATE] Direction: ${direction == TranslationDirection.viToEn ? "VI→EN" : "EN→VI"}');

      final result = await _translationService.translate(
        inputText.trim(),
        direction: direction,
      );

      print('✅ [CREATE] Translation result: vietnamese="${result.vietnamese ?? 'N/A'}", english="${result.english}"');

      String vietnameseField;
      String englishField;

      if (direction == TranslationDirection.viToEn) {
        vietnameseField = inputText.trim();
        englishField = result.english;
      } else {
        vietnameseField = result.vietnamese ?? inputText.trim();
        englishField = inputText.trim();
      }

      final newCard = Flashcard(
        vietnamese: vietnameseField,
        english: englishField,
        phonetic: result.phonetic,
        partOfSpeech: result.partOfSpeech,
        examples: result.examples,
        imageUrl: result.imageUrl,
        folderId: folderId ?? currentFolderId.value,
      );

      print('🎉 [CREATE] Flashcard prepared: vietnamese="${newCard.vietnamese}", english="${newCard.english}"');
      return newCard;
    } catch (e) {
      print('❌ [CREATE] Translation error: $e');
      _showError('Không thể dịch từ này', e);
      return null;
    } finally {
      isTranslating.value = false;
    }
  }

  Future<void> saveFlashcard(Flashcard flashcard) async {
    try {
      isLoading.value = true;
      await _repository.createFlashcard(flashcard);
      Get.snackbar('Thành công', 'Đã lưu flashcard!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể lưu flashcard', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      isLoading.value = true;
      await _repository.updateFlashcard(flashcard);
      _updateHasUnmemorized();
      Get.snackbar('Thành công', 'Đã cập nhật flashcard!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể cập nhật flashcard', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _repository.deleteFlashcard(flashcardId);
      _updateHasUnmemorized();
      Get.snackbar('Đã xóa', 'Flashcard đã được xóa',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể xóa flashcard', e);
    }
  }

  Future<void> toggleMemorized(String flashcardId, bool isMemorized) async {
    try {
      await _repository.markAsMemorized(flashcardId, isMemorized);
      _updateHasUnmemorized();
    } catch (e) {
      _showError('Không thể cập nhật trạng thái', e);
    }
  }

  Future<void> resetAllFlashcards() async {
    try {
      isLoading.value = true;
      await _repository.resetAllFlashcards();
      _updateHasUnmemorized();
      Get.snackbar('Đã reset', 'Tất cả flashcard đã được đặt lại',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      _showError('Không thể reset flashcards', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> moveToFolder(String flashcardId, String newFolderId) async {
    try {
      await _repository.moveToFolder(flashcardId, newFolderId);
      _updateHasUnmemorized();
      Get.snackbar('Thành công', 'Đã chuyển flashcard',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể chuyển flashcard', e);
    }
  }


  void loadFolders() {
    _folderSubscription?.cancel();
    _folderSubscription = _repository.getFolders().listen(
          (folderList) => folders.value = folderList,
      onError: (e) => _showError('Không thể tải thư mục', e),
    );
  }

  Future<String?> createFolder(FlashcardFolder folder) async {
    try {
      isLoading.value = true;
      final folderId = await _repository.createFolder(folder);
      Get.snackbar('Thành công', 'Đã tạo thư mục mới!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
      return folderId;
    } catch (e) {
      _showError('Không thể tạo thư mục', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFolder(FlashcardFolder folder) async {
    try {
      isLoading.value = true;
      await _repository.updateFolder(folder);
      Get.snackbar('Thành công', 'Đã cập nhật thư mục!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể cập nhật thư mục', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFolder(String folderId, {bool moveToDefault = true}) async {
    try {
      isLoading.value = true;
      await _repository.deleteFolder(folderId, moveToDefault: moveToDefault);

      if (currentFolderId.value == folderId) {
        loadFlashcardsByFolder('default');
      }

      Get.snackbar('Đã xóa', 'Thư mục đã được xóa',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } catch (e) {
      _showError('Không thể xóa thư mục', e);
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> loadStatistics() async {
    try {
      final stats = currentFolderId.value == 'default'
          ? await _repository.getStatistics()
          : await _repository.getStatisticsByFolder(currentFolderId.value);
      statistics.value = stats;
    } catch (e) {
      _showError('Không thể tải thống kê', e);
    }
  }

  Future<void> loadStatisticsByFolder(String folderId) async {
    try {
      final stats = await _repository.getStatisticsByFolder(folderId);
      statistics.value = stats;
    } catch (e) {
      _showError('Không thể tải thống kê', e);
    }
  }


  Flashcard? getNextFlashcard() {
    final toReview = flashcards.where((f) => !f.isMemorized).toList();
    if (toReview.isEmpty) return null;
    toReview.sort((a, b) => a.lastReviewed.compareTo(b.lastReviewed));
    return toReview.first;
  }

  Flashcard? getRandomFlashcard() {
    if (flashcards.isEmpty) return null;
    final shuffled = List<Flashcard>.from(flashcards)..shuffle();
    return shuffled.first;
  }

  void _showError(String title, dynamic error) {
    print('$title: $error');
    Get.snackbar(
      title,
      error.toString().split(':').last.trim(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 3),
    );
  }
}