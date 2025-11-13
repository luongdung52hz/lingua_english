import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/quiz_model.dart';
import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/quiz_controller.dart';
import '../../widgets/info_card.dart';
import '../../widgets/search_bar.dart'; // Import SearchBarWidget

class QuizListScreen extends StatelessWidget {
  QuizListScreen({super.key});

  final QuizController controller = Get.put(QuizController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Danh sách Quiz',
          style: AppTextStyles.headline,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: 'Tạo quiz mới',
            onPressed: () => context.push('/quiz/create'),
          ),
        ],
      ),

      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final allQuizzes = controller.quizzes; // Use all quizzes for display
            final searchQuery = controller.searchQuery.value.trim();
            final filteredList = searchQuery.isEmpty
                ? allQuizzes
                : allQuizzes.where((quiz) =>
            quiz.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (quiz.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
            ).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: SearchBarWidget(
                    onChanged: (value) {
                      controller.searchQuery.value = value.trim();
                    },
                    onSubmitted: (value) {
                      controller.searchQuery.value = value.trim();
                    },
                    onClear: () {
                      controller.searchQuery.value = '';
                    },
                    hintText: 'Tìm kiếm theo tiêu đề...',
                    prefixIcon: Icons.search,
                    clearIcon: Icons.clear,
                    fillColor: Colors.white,
                    iconSize: 20,
                    borderRadius: BorderRadius.circular(12),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),

                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                    child: Text(
                      searchQuery.isEmpty ? 'Không có quiz nào' : 'Không tìm thấy quiz nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: () async {
                      await controller.fetchAllQuizzes();
                    },
                    child: ListView.builder(
                      key: ValueKey('quiz_list_${filteredList.length}'),
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final quiz = filteredList[index];
                        return InfoCard(
                          title: quiz.title,
                          subtitle: quiz.description,
                          infoPairs: [
                            IconTextPair(Icons.quiz, '${quiz.totalQuestions} câu hỏi'), // Reusable info pair
                          ],
                        //  isCompleted: false, // Or from model if available (e.g., quiz.isCompleted)
                          onTap: () => context.push('/quiz/detail/${quiz.id}'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}