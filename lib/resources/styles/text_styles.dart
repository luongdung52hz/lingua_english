import 'package:flutter/material.dart';

import 'colors.dart';

class AppTextStyles {
  // Tiêu đề lớn
  static const TextStyle headlinew = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );

  static const TextStyle headlineb = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );

  // Tiêu đề vừa
  static const TextStyle title = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // Nội dung bình thường
  static const TextStyle body = TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );

  // Nội dung nhấn mạnh
  static const TextStyle bodyBold = TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );

  // Placeholder hoặc hint
  static const TextStyle hint = TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.normal,
    fontSize: 14,
  );

  // Label focus (ví dụ cho TextField)
  static const TextStyle labelFocus = TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );
}
