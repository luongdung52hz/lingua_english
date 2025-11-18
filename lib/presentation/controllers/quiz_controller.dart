import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/quiz_repository.dart';


class QuizController extends GetxController {
  final QuizRepository _repository = QuizRepository();

  // Reactive variables
  var quizzes = <QuizModel>[].obs;
  var isLoading = false.obs;
  var quizCount = 0.obs;
  var selectedStatus = QuizStatus.draft.obs;  // For filter
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllQuizzes();
    fetchQuizCount();
  }

  // Lấy tất cả quizzes
  Future<void> fetchAllQuizzes() async {
    isLoading.value = true;
    try {
      final list = await _repository.getAllQuizzes();
      quizzes.value = list;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không tải được danh sách quiz: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Lấy quiz theo ID
  Future<QuizModel?> getQuizById(String id) async {
    try {
      return await _repository.getQuizById(id);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không tìm thấy quiz: $e');
      return null;
    }
  }

  // Tạo quiz mới
  Future<void> createQuiz(QuizModel quiz) async {
    try {
      final newId = const Uuid().v4();
      final newQuiz = quiz.copyWith(id: newId);
      await _repository.saveQuiz(newQuiz);
      quizzes.add(newQuiz);
      Get.snackbar('Thành công', 'Quiz đã được lưu!');
      Get.back();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không lưu được quiz: $e');
    }
  }

  // Update quiz
  Future<void> updateQuiz(QuizModel quiz) async {
    try {
      await _repository.updateQuiz(quiz);
      final index = quizzes.indexWhere((q) => q.id == quiz.id);
      if (index != -1) {
        quizzes[index] = quiz;
        quizzes.refresh();
      }
      Get.snackbar('Thành công', 'Quiz đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không cập nhật được quiz: $e');
    }
  }

  // Xóa quiz
  Future<void> deleteQuiz(String id) async {
    try {
      await _repository.deleteQuiz(id);
      quizzes.removeWhere((q) => q.id == id);
      Get.snackbar('Thành công', 'Quiz đã bị xóa!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không xóa được quiz: $e');
    }
  }

  // Tìm kiếm (local filter)
  List<QuizModel> get filteredQuizzes {
    return quizzes.where((q) {
      final matchesStatus = selectedStatus.value == QuizStatus.draft || q.status == selectedStatus.value;  // Default all if draft
      final matchesSearch = q.title.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  get currentQuiz => null;

  get localScores => null;

  // Lấy theo status (cập nhật reactive)
  Future<void> filterByStatus(QuizStatus status) async {
    selectedStatus.value = status;
  }

  // Đếm quiz
  Future<void> fetchQuizCount() async {
    try {
      final count = await _repository.getQuizCount();
      quizCount.value = count ?? 0;
    } catch (e) {
      quizCount.value = 0;
    }
  }

  // Publish quiz (update status)
  Future<void> publishQuiz(QuizModel quiz) async {
    final publishedQuiz = quiz.copyWith(status: QuizStatus.published);
    await updateQuiz(publishedQuiz);
  }

  void submitAnswer(String quizId, String s, int currentQuestionIndex, String t) {}

  getQuizStream(String quizId) {}

  void setCurrentQuiz(quiz) {}

  Future generateQuiz({required String level, required String topic, required int numQuestions, required int timePerQuestion}) async {}
}