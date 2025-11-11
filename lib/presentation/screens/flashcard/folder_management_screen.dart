// lib/ui/screens/folder_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/flashcard_model.dart';
import '../../controllers/flashcard_controller.dart';

class FolderManagementScreen extends StatelessWidget {
  const FolderManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thư mục'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.folders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.folders.length,
          itemBuilder: (context, index) {
            final folder = controller.folders[index];
            return _FolderCard(folder: folder);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderDialog(context, controller),
        icon: const Icon(Icons.create_new_folder, color: Colors.white),
        label: const Text('Tạo thư mục mới',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _showCreateFolderDialog(
      BuildContext context, FlashcardController controller) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = '📚';
    String selectedColor = '#9C27B0';

    final icons = ['📚', '🎯', '💼', '🎓', '🌟', '📝', '🔖', '📌', '🎨', '🚀'];
    final colors = [
      '#9C27B0', '#2196F3', '#4CAF50', '#FF9800',
      '#F44336', '#00BCD4', '#E91E63', '#FFC107',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo thư mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thư mục *',
                    hintText: 'Ví dụ: Từ vựng công việc',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    hintText: 'Mô tả ngắn về thư mục',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                const Text('Chọn biểu tượng:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // ✅ GridView để canh giữa & đều biểu tượng
                SizedBox(
                  height: 100,
                  child: GridView.count(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    children: icons.map((icon) {
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple.withOpacity(0.15)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(icon,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Chọn màu:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${color.substring(1)}',
                              radix: 16)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  Get.snackbar('Lỗi', 'Vui lòng nhập tên thư mục');
                  return;
                }

                final folder = FlashcardFolder(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                );

                await controller.createFolder(folder);
                Navigator.pop(context);
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FlashcardFolder folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();
    final isDefault = folder.id == 'default';
    final color = Color(int.parse('FF${folder.color.substring(1)}', radix: 16));

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          controller.loadFlashcardsByFolder(folder.id!);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white, // ✅ bỏ gradient, nền trắng tinh tế
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(folder.icon,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(folder.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Mặc định',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (folder.description != null) ...[
                      const SizedBox(height: 4),
                      Text(folder.description!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.style,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${folder.cardCount} flashcards',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isDefault)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Get.snackbar('Thông báo', 'Tính năng chỉnh sửa sắp ra mắt');
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, controller);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FlashcardController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thư mục'),
        content: Text('Bạn có chắc muốn xóa thư mục "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteFolder(folder.id!, moveToDefault: true);
            },
            child: const Text('Chuyển về "Tất cả"'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteFolder(folder.id!, moveToDefault: false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
