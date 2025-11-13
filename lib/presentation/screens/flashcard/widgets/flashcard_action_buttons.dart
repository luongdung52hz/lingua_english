// lib/ui/widgets/action_buttons.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../resources/styles/colors.dart';
import '../../../widgets/app_button.dart'; // Import CustomButton

class ActionButtons extends StatelessWidget {
  final VoidCallback? onCreatePressed;
  final VoidCallback? onStudyPressed;
  final bool studyEnabled;
  final String? createLabel;
  final IconData? createIcon;
  final IconData? studyIcon;
  final Color? studyBackgroundColor;
  final double? studyIconSize;

  const ActionButtons({
    Key? key,
    this.onCreatePressed,
    this.onStudyPressed,
    this.studyEnabled = true,
    this.createLabel = 'Tạo flashcard mới',
    this.createIcon = Icons.add,
    this.studyIcon = Icons.school,
    this.studyBackgroundColor,
    this.studyIconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomButton(
              onPressed: onCreatePressed,
              text: createLabel ?? 'Tạo flashcard mới',
              icon: createIcon ?? Icons.add,
              iconSize: 20, // Adjust if needed
              height: 52, // Match original height
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Adjust for text + icon fit
              borderRadius: BorderRadius.circular(12),
              // No loading, no shadow/gradient for simplicity
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 52, // Chiều cao bằng với nút Tạo flashcard
            width: 52,  // Vuông để icon nằm giữa
            child: CustomButton(
              onPressed: studyEnabled ? onStudyPressed : null,
              text: '', // Empty text for icon-only
              buttonColor: Colors.green,
              icon: studyIcon ?? Icons.school,
              iconSize: studyIconSize ?? 24,
              height: 52,
              padding: EdgeInsets.zero, // No padding for square fit
              borderRadius: BorderRadius.circular(12),
              // Custom color via decoration if supported; otherwise, override style if needed
            ),
          ),
        ],
      ),
    );
  }
}