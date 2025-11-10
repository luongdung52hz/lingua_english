// lib/ui/widgets/unmemorized_filter_chip.dart

import 'package:flutter/material.dart';

class UnmemorizedFilterChip extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const UnmemorizedFilterChip({
    Key? key,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isSelected ? 'Hiện tất cả' : 'Chỉ hiện chưa thuộc',
      onPressed: () => onSelected(!isSelected),
      icon: Icon(
        isSelected ? Icons.filter_alt : Icons.filter_alt_outlined,
        color: isSelected ? Colors.blueAccent : Colors.grey,
      ),
    );
  }
}
