import 'package:flutter/material.dart';
import '../../../resources/styles/colors.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed; // Callback khi nhấn (có thể null để disable)
  final String text; // Text hiển thị trên nút
  final bool isLoading; // State loading
  final double height; // Chiều cao nút (mặc định 50)
  final EdgeInsetsGeometry padding; // Padding nội dung (mặc định như code của bạn)
  final BorderRadius borderRadius; // Bo góc (mặc định 10)
  final BoxShadow? boxShadow; // Shadow tùy chỉnh
  final IconData? icon; // Icon tùy chọn (mới thêm)
  final double? iconSize; // Kích thước icon (mặc định 20, mới thêm)
  final FontWeight? fontWeight;  // NEW: Tùy chọn font weight
  final Color? buttonColor; // NEW: Màu nền nút (mặc định AppColors.primary)

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 110, vertical: 15),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.boxShadow,
    this.icon, // Optional icon
    this.iconSize, // Optional icon size
    this.fontWeight = FontWeight.bold,  // Mặc định bold, dễ override
    this.buttonColor, // Optional button color
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = buttonColor ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      child: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: isLoading ? null : onPressed,
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: borderRadius,
              //boxShadow: boxShadow ?? [], // Áp dụng shadow nếu có
            ),
            child: Center(
              child: icon != null
                  ? Row( // Row cho icon + text nếu có icon
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize ?? 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: fontWeight ?? FontWeight.bold,  // Dùng param                      fontSize: 15,
                    ),
                  ),
                ],
              )
                  : Text( // Fallback chỉ text nếu không có icon
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: fontWeight ?? FontWeight.bold,  // Dùng param                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}