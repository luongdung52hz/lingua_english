// lib/ui/widgets/move_to_folder_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/flashcard_model.dart';
import '../../../controllers/flashcard_controller.dart';

class MoveToFolderDialog extends StatelessWidget {
  final Flashcard flashcard;
  final Function(String) onMove;

  const MoveToFolderDialog({
    Key? key,
    required this.flashcard,
    required this.onMove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();

    return AlertDialog(
      title: const Text('Chuyển đến thư mục'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Giới hạn chiều cao
        child: Obx(() {
          final availableFolders = controller.folders
              .where((f) => f.id != flashcard.folderId)
              .toList();

          if (availableFolders.isEmpty) {
            return const Center(
              child: Text('Không có thư mục nào khác'),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: availableFolders.length,
            itemBuilder: (context, index) {
              final folder = availableFolders[index];
              return ListTile(
                leading: Text(folder.icon, style: const TextStyle(fontSize: 28)),
                title: Text(
                  folder.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${folder.cardCount} thẻ'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  onMove(folder.id!);
                  Navigator.pop(context); // ĐÓNG DIALOG SAU KHI CHỌN
                },
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}