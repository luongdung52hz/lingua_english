// lib/ui/widgets/folder_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../resources/styles/colors.dart';
import '../../../controllers/flashcard_controller.dart';

class FolderChips extends StatelessWidget {
  const FolderChips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();

    return Obx(() {
      if (controller.folders.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.folders.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final folder = controller.folders[index];

            return Obx(() {
              final currentId = controller.currentFolderId.value;
              final isSelected = folder.id == currentId;

              return GestureDetector(
                onTap: () {
                  final newId = folder.id ?? 'default';
                  controller.currentFolderId.value = newId;

                  if (newId == 'default') {
                    controller.loadFlashcards();
                  } else {
                    controller.loadFlashcardsByFolder(newId);
                  }

                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                      // BoxShadow(
                      //   color: AppColors.primary,
                      //   blurRadius: 6,
                      //   offset: const Offset(0, 2),
                      // )
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          folder.icon,
                          style: const TextStyle(fontSize: 18, height: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Center(
                        child: Text(
                          folder.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (folder.cardCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          alignment: Alignment.center,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${folder.cardCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            });
          },

        ),
      );
    });
  }
}
