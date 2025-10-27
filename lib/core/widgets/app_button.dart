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
  final LinearGradient? gradient; // Gradient tùy chỉnh (mặc định primaryGradient)

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 110, vertical: 15),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
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
       //   borderRadius: borderRadius,
          onTap: isLoading ? null : onPressed,
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: borderRadius,
              boxShadow:  AppColors.primaryShadow,
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}