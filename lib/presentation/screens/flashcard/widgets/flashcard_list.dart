// lib/ui/widgets/flashcard_list.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/flashcard_model.dart';
import '../../../controllers/flashcard_controller.dart';
import 'flashcard_item.dart';

class FlashcardList extends StatelessWidget {
  final String searchText;
  final bool showOnlyUnmemorized;
  final Function(Flashcard) onTapFlashcard;
  final Function(String, bool) onToggleMemorized;
  final Function(Flashcard) onMoveToFolder;
  final Function(Flashcard) onDeleteFlashcard;

  const FlashcardList({
    Key? key,
    required this.searchText,
    required this.showOnlyUnmemorized,
    required this.onTapFlashcard,
    required this.onToggleMemorized,
    required this.onMoveToFolder,
    required this.onDeleteFlashcard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      List<Flashcard> filteredFlashcards = controller.flashcards;

      if (filteredFlashcards.isEmpty) {
        return Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  searchText.isNotEmpty ? 'Không tìm thấy' : 'Chưa có flashcard',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  searchText.isNotEmpty
                      ? 'Thử từ khóa khác'
                      : 'Nhấn "Tạo flashcard mới" để bắt đầu',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        color: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredFlashcards.length,
          itemBuilder: (context, index) {
            final flashcard = filteredFlashcards[index];
            return FlashcardItem(
              flashcard: flashcard,
              onTap: () => onTapFlashcard(flashcard),
              onToggleMemorized: () =>
                  onToggleMemorized(flashcard.id!, flashcard.isMemorized),
              onMoveToFolder: () => onMoveToFolder(flashcard),
              onDelete: () => onDeleteFlashcard(flashcard),
            );
          },
        ),
      );
    });
  }
}
