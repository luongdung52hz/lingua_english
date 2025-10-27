import 'package:flutter/material.dart';

class SkillUtils {
  static final Map<String, Color> skillColors = {
    'listening': Colors.blue,
    'speaking': Colors.orange,
    'reading': Colors.green,
    'writing': Colors.purple,
  };

  static Color getSkillColor(String skill) {
    return skillColors[skill] ?? Colors.grey;
  }

  static IconData getSkillIcon(String skill) {
    switch (skill) {
      case 'listening':
        return Icons.headphones_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'writing':
        return Icons.edit_rounded;
      default:
        return Icons.help_outline;
    }
  }
}