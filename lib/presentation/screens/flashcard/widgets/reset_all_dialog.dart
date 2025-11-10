// lib/ui/widgets/reset_all_dialog.dart

import 'package:flutter/material.dart';

class ResetAllDialog extends StatelessWidget {
  final VoidCallback onReset;

  const ResetAllDialog({
    Key? key,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset tất cả'),
      content: const Text('Đặt lại tất cả flashcard về trạng thái "chưa thuộc"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onReset();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}