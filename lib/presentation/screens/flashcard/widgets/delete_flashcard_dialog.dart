// lib/ui/widgets/delete_flashcard_dialog.dart

import 'package:flutter/material.dart';
import '../../../../data/models/flashcard_model.dart';

class DeleteFlashcardDialog extends StatelessWidget {
  final Flashcard flashcard;
  final VoidCallback onDelete;

  const DeleteFlashcardDialog({
    Key? key,
    required this.flashcard,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Xóa flashcard "${flashcard.vietnamese}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}