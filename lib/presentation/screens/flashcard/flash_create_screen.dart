// lib/ui/screens/flashcard_create_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../data/datasources/remote/translation_service.dart'; // ✅ Import để dùng enum
import '../../../resources/styles/colors.dart';
import '../../controllers/flashcard_controller.dart';
import '../../widgets/app_button.dart'; // Import CustomButton

class FlashcardCreateScreen extends StatefulWidget {
  const FlashcardCreateScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardCreateScreen> createState() => _FlashcardCreateScreenState();
}

class _FlashcardCreateScreenState extends State<FlashcardCreateScreen> {
  final FlashcardController controller = Get.find<FlashcardController>();
  final TextEditingController textController = TextEditingController();
  Flashcard? previewFlashcard;
  String? selectedFolderId;

  TranslationDirection translationDirection = TranslationDirection.viToEn;

  @override
  void initState() {
    super.initState();
    selectedFolderId = controller.currentFolderId.value;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _translateAndPreview() async {
    final inputText = textController.text.trim();
    if (inputText.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập từ/câu cần dịch',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final flashcard = await controller.createFlashcardFromText(
      inputText,
      direction: translationDirection,
      folderId: selectedFolderId,
    );

    if (flashcard != null) {
      setState(() => previewFlashcard = flashcard);
    }
  }

  Future<void> _saveFlashcard() async {
    if (previewFlashcard != null) {
      await controller.saveFlashcard(previewFlashcard!);
      textController.clear();
      setState(() => previewFlashcard = null);
    }
  }

  void _toggleTranslationDirection() {
    setState(() {
      translationDirection = translationDirection == TranslationDirection.viToEn
          ? TranslationDirection.enToVi
          : TranslationDirection.viToEn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Flashcard Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Quản lý thư mục',
            onPressed: () {
              GoRouter.of(context).push('/flashcards/folders');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFolderSelector(),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            translationDirection == TranslationDirection.viToEn
                                ? ' Dịch tiếng Việt → Anh'
                                : ' Dịch tiếng Anh → Việt',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.swap_horiz,
                              color: Colors.black,
                              size: 28,
                            ),
                            tooltip: 'Đổi hướng dịch',
                            onPressed: _toggleTranslationDirection,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: translationDirection == TranslationDirection.viToEn
                            ? 'Ví dụ: Xin chào'
                            : 'Example: Hello',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _translateAndPreview(),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Obx(() => CustomButton(
                        onPressed: controller.isTranslating.value
                            ? null
                            : () {
                          FocusScope.of(context).unfocus();

                          HapticFeedback.mediumImpact();

                          _translateAndPreview();
                        },
                        text: controller.isTranslating.value
                            ? 'Đang dịch ...'
                            : 'Dịch ngay ',
                        icon: controller.isTranslating.value
                            ? null  // Spinner handled by isLoading, but since no isLoading, use custom icon if needed
                            : Icons.auto_awesome,
                        iconSize: 20,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Giảm horizontal padding để tránh overflow
                        buttonColor: AppColors.primary,
                      )),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview card
            if (previewFlashcard != null) ...[
              const Text(
                ' Xem trước Flashcard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPreviewCard(previewFlashcard!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () {
                        setState(() => previewFlashcard = null);
                      },
                      text: 'Hủy',
                      icon: Icons.cancel,
                      iconSize: 18, // Giảm icon size để tiết kiệm space
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Giảm horizontal padding
                      borderRadius: BorderRadius.circular(12),
                      buttonColor: Colors.grey.shade300, // Light color for outlined-like effect
                    ),
                  ),
                  const SizedBox(width: 8), // Giảm width giữa hai nút để cân bằng
                  Expanded(
                    child: Obx(() => CustomButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : _saveFlashcard,
                      text: 'Lưu', // Rút gọn text để tránh overflow (hoặc dùng 'Lưu FC' nếu cần)
                      icon: Icons.save,
                      iconSize: 18, // Giảm icon size
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Giảm horizontal padding
                      borderRadius: BorderRadius.circular(12),
                      buttonColor: Colors.green,
                    )),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelector() {
    return Obx(() {
      final folders = controller.folders;
      final selectedFolder =
      folders.firstWhereOrNull((f) => f.id == selectedFolderId);

      return Card(
        elevation: 2,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Text(
            selectedFolder?.icon ?? '📚',
            style: const TextStyle(fontSize: 32),
          ),
          title: const Text('Lưu vào thư mục'),
          subtitle: Text(selectedFolder?.name ?? 'Chọn thư mục'),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () => _showFolderPicker(),
        ),
      );
    });
  }

  void _showFolderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Obx(() {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn thư mục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.folders.length,
                  itemBuilder: (context, index) {
                    final folder = controller.folders[index];
                    final isSelected = folder.id == selectedFolderId;
                    final color = Color(
                      int.parse('FF${folder.color.substring(1)}', radix: 16),
                    );

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(folder.icon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      title: Text(folder.name),
                      subtitle: Text('${folder.cardCount} flashcards'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() => selectedFolderId = folder.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPreviewCard(Flashcard flashcard) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vietnamese (Front)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mặt trước (Tiếng Việt)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flashcard.vietnamese,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // English (Back)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mặt sau (Tiếng Anh)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flashcard.english,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  // FIXED: Wrap Row with Flexible to prevent overflow
                  if (flashcard.phonetic != null || flashcard.partOfSpeech != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (flashcard.phonetic != null) ...[
                          Flexible( // NEW: Flexible to allow wrap/ellipsis
                            child: Text(
                              ' ${flashcard.phonetic}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis, // NEW: Ellipsis if too long
                              maxLines: 1,
                            ),
                          ),
                        ],
                        if (flashcard.partOfSpeech != null) ...[
                          const SizedBox(width: 8),
                          Flexible( // NEW: Flexible for Chip
                            child: Chip(
                              label: Text(flashcard.partOfSpeech!),
                              backgroundColor: Colors.blue[50],
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Examples
            if (flashcard.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '📚 Ví dụ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...flashcard.examples.map(
                    (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded( // NEW: Expanded to prevent overflow in examples
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis, // NEW: Ellipsis if long
                          maxLines: 2, // Limit lines
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}