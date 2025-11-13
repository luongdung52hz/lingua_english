import 'package:flutter/material.dart';

class AppColors {
  // Các màu cơ bản
  static const Color  primary = Color(0xFF00c0e7);
  static const Color secondary= Color(0xFF4a91e2);
  static const Color grey = Colors.grey;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4a91e2),
      Color(0xFF00aaec),
      Color(0xFF00c0e7),
      Color(0xFF00d2d7),
      //Color(0xFF50e2c2),

    ],
  );

  static const List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Colors.black26,
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static final OutlineInputBorder yBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.grey,
        width: 1,
      )
  );

  static const Border primaryBorder = Border(
    left: BorderSide(color: grey, width: 1),
    top: BorderSide(color: grey, width: 1),
    right: BorderSide(color: grey, width: 1),
    bottom: BorderSide(color: grey, width: 1),
  );

  static final OutlineInputBorder successBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1,
      )
  );

  static final OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.red, width: 1,

      )
  );



}