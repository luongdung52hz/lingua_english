// lib/ui/widgets/flashcard_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';

import '../../../../resources/styles/colors.dart';
import '../../../controllers/flashcard_controller.dart';

class FlashcardActionButtons extends StatelessWidget {
  const FlashcardActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Create button (main action)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/flashcards/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo flashcard mới',style: TextStyle(fontWeight: FontWeight.w900,fontSize: 14),),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Study button
          _buildStudyButton(),
        ],
      ),
    );
  }

  Widget _buildStudyButton() {
    return StreamBuilder(
      builder: (context, snapshot) {
        final hasUnmemorized = true; // Fetch từ controller sau
        return SizedBox(
          height: 52, // Chiều cao bằng với nút Tạo flashcard
          width: 52,  // Vuông để icon nằm giữa
          child: ElevatedButton(
            onPressed: hasUnmemorized ? () => context.push('/flashcards/study') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero, // Loại bỏ padding mặc định
            ),
            child: const Center(
              child: Icon(Icons.school, size: 24),
            ),
          ),
        );
      },
      stream: null,
    );
  }

}