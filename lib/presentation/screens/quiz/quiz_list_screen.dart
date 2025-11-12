import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/screens/quiz/widgets/quiz_card.dart';
import '../../../data/models/quiz_model.dart';
import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/quiz_controller.dart';

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

            final filteredList = controller.filteredQuizzes;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    cursorColor: Colors.grey,
                    onChanged: (value) =>
                    controller.searchQuery.value = value.trim(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tiêu đề...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                    child: Text(
                      'Không tìm thấy quiz nào',
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
                        return QuizCard(
                          key: ValueKey(quiz.id),
                          quiz: quiz,
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
