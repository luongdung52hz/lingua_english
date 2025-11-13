// lib/ui/widgets/search_bar.dart

import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? clearIcon;
  final Color? fillColor;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;
  final double? iconSize;
  final BorderRadius? borderRadius;

  const SearchBarWidget({
    Key? key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText,
    this.prefixIcon,
    this.clearIcon,
    this.fillColor,
    this.padding,
    this.contentPadding,
    this.iconSize,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController();
    final effectiveHintText = hintText ?? 'Tìm kiếm...';
    final effectivePrefixIcon = prefixIcon ?? Icons.search;
    final effectiveClearIcon = clearIcon ?? Icons.clear;
    final effectiveFillColor = fillColor ?? Colors.grey[100];
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 16);
    final effectiveContentPadding = contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final effectiveIconSize = iconSize ?? 20.0;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Padding(
      padding: effectivePadding,
      child: TextField(
        controller: effectiveController,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: effectiveHintText,
          prefixIcon: Icon(effectivePrefixIcon, size: effectiveIconSize),
          suffixIcon: effectiveController.text.isNotEmpty
              ? IconButton(
            icon: Icon(effectiveClearIcon, size: effectiveIconSize),
            onPressed: () {
              effectiveController.clear();
              onClear?.call();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: effectiveBorderRadius,
        //    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: effectiveFillColor,
          contentPadding: effectiveContentPadding,
          isDense: true,
        ),
      ),
    );
  }
}