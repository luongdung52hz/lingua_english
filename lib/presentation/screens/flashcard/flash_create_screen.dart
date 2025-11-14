// lib/ui/screens/flashcard_create_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../data/datasources/remote/translation_service.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/flashcard_controller.dart';
import '../../widgets/app_button.dart';

class FlashcardCreateScreen extends StatefulWidget {
  const FlashcardCreateScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardCreateScreen> createState() => _FlashcardCreateScreenState();
}

class _FlashcardCreateScreenState extends State<FlashcardCreateScreen> {
  final FlashcardController controller = Get.find<FlashcardController>();
  final TextEditingController textController = TextEditingController();

  // Controllers for manual input
  final TextEditingController vietnameseController = TextEditingController();
  final TextEditingController englishController = TextEditingController();
  final TextEditingController phoneticController = TextEditingController();
  // Removed unused partOfSpeechController
  final TextEditingController examplesController = TextEditingController();

  final List<String> partOfSpeechOptions = [
    'noun',
    'verb',
    'adjective',
    'adverb',
    'pronoun',
    'preposition',
    'conjunction',
    'interjection',
    'other',
  ];

  Flashcard? previewFlashcard;
  String? selectedFolderId;
  bool isManualMode = false;
  String? selectedPartOfSpeech;

  TranslationDirection translationDirection = TranslationDirection.viToEn;

  @override
  void initState() {
    super.initState();
    // Set default folder if current is empty/null
    selectedFolderId = controller.currentFolderId.value.isNotEmpty
        ? controller.currentFolderId.value
        : 'default';
  }

  @override
  void dispose() {
    textController.dispose();
    vietnameseController.dispose();
    englishController.dispose();
    phoneticController.dispose();
    // Removed partOfSpeechController.dispose()
    examplesController.dispose();
    super.dispose();
  }

  Future<void> _translateAndPreview() async {
    final inputText = textController.text;
    if (inputText.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập từ/câu cần dịch',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Added null check for folder
    if (selectedFolderId == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn thư mục',
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

  void _createManualFlashcard() {
    if (vietnameseController.text.isEmpty || englishController.text.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập đầy đủ mặt trước và mặt sau',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Added null check for folder
    if (selectedFolderId == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn thư mục',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final examples = examplesController.text.isEmpty
        ? <String>[]
        : examplesController.text
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();

    final flashcard = Flashcard(
      id: const Uuid().v4(),
      vietnamese: vietnameseController.text,
      english: englishController.text,
      phonetic: phoneticController.text.isEmpty ? null : phoneticController.text,
      partOfSpeech: selectedPartOfSpeech,
      createdAt: DateTime.now(),
      examples: examples,
      folderId: selectedFolderId!, // Safe now due to check above
      isMemorized: false,
    );

    setState(() => previewFlashcard = flashcard);
  }

  Future<void> _saveFlashcard() async {
    if (previewFlashcard != null) {
      await controller.saveFlashcard(previewFlashcard!);
      textController.clear();
      vietnameseController.clear();
      englishController.clear();
      phoneticController.clear();
      // Removed partOfSpeechController.clear()
      examplesController.clear();
      setState(() => previewFlashcard = null);
    }
  }

  void _toggleTranslationDirection() {
    setState(() {
      translationDirection = translationDirection == TranslationDirection.viToEn
          ? TranslationDirection.enToVi
          : TranslationDirection.viToEn;
      // Clear text when changing direction
      textController.clear();
    });
  }

  void _toggleInputMode() {
    // Unfocus any active text field first
    FocusScope.of(context).unfocus();

    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();

    // Update state - this will trigger immediate rebuild
    setState(() {
      isManualMode = !isManualMode;
      previewFlashcard = null;

      // Clear all input fields
      textController.clear();
      vietnameseController.clear();
      englishController.clear();
      phoneticController.clear();
      // Removed partOfSpeechController.clear()
      examplesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isManualMode ? 'Tạo Flashcard (Thủ công)' : 'Tạo Flashcard (AI)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isManualMode ? Icons.auto_awesome : Icons.edit),
            tooltip: isManualMode ? 'Chế độ AI' : 'Chế độ thủ công',
            onPressed: _toggleInputMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Add key to force rebuild when mode changes
        key: ValueKey('input_mode_$isManualMode'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFolderSelector(),
            const SizedBox(height: 16),

            // Input Section - will rebuild based on isManualMode
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isManualMode
                  ? _buildManualInputSection()
                  : _buildAIInputSection(),
            ),

            const SizedBox(height: 24),

            // Preview card
            if (previewFlashcard != null) ...[
              const Text(
                'Xem trước Flashcard',
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
                      iconSize: 18,
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      borderRadius: BorderRadius.circular(12),
                      buttonColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => CustomButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : _saveFlashcard,
                      text: 'Lưu',
                      icon: Icons.save,
                      iconSize: 18,
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

  Widget _buildAIInputSection() {
    return Card(
      // Add unique key for AnimatedSwitcher
      key: const ValueKey('ai_mode'),
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
                        ? 'Dịch tiếng Việt → Anh'
                        : 'Dịch tiếng Anh → Việt',
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
                    icon: const Icon(
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
                    width: 1,
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
                    : 'Dịch ngay',
                icon: controller.isTranslating.value
                    ? null
                    : Icons.auto_awesome,
                iconSize: 20,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                buttonColor: AppColors.primary,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Card(
      // Add unique key for AnimatedSwitcher
      key: const ValueKey('manual_mode'),
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
            const Text(
              'Nhập thủ công',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Vietnamese
            TextField(
              controller: vietnameseController,
              decoration: InputDecoration(
                labelText: 'Tiếng Việt (Mặt trước)*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // English
            TextField(
              controller: englishController,
              decoration: InputDecoration(
                labelText: 'Tiếng Anh (Mặt sau)*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Phonetic
            TextField(
              controller: phoneticController,
              decoration: InputDecoration(
                labelText: 'Phiên âm (tùy chọn)',
                hintText: '/həˈloʊ/',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Part of Speech
            DropdownButtonFormField<String>(
              value: selectedPartOfSpeech,
              decoration: InputDecoration(
                labelText: 'Từ loại (tùy chọn)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              dropdownColor: Colors.white, // Nền trắng cho menu
              borderRadius: BorderRadius.circular(12),
              items: partOfSpeechOptions.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPartOfSpeech = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Examples
            TextField(
              controller: examplesController,
              decoration: InputDecoration(
                labelText: 'Ví dụ (tùy chọn)',
                hintText: 'Mỗi ví dụ trên một dòng',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Center(
              child: CustomButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  HapticFeedback.mediumImpact();
                  _createManualFlashcard();
                },
                text: 'Tạo Flashcard',
                icon: Icons.add_card,
                iconSize: 20,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                buttonColor: AppColors.primary,
              ),
            ),
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
          color: Colors.white, // Added: Set background to white
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Chọn thư mục',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Quản lý thư mục',
                    onPressed: () {
                      Navigator.pop(context); // Added: Close bottom sheet first
                      GoRouter.of(context).push('/flashcards/folders');
                    },
                  ),
                ],
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
                          borderRadius: BorderRadius.circular(12), // Changed to 12
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
      color: Colors.grey.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vietnamese
            Text(
              flashcard.vietnamese,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 24),

            // English
            Text(
              flashcard.english,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Phonetic & Part of Speech
            if (flashcard.phonetic != null || flashcard.partOfSpeech != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (flashcard.phonetic != null)
                    Flexible(
                      child: Text(
                        flashcard.phonetic!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (flashcard.phonetic != null && flashcard.partOfSpeech != null)
                    Text('  •  ', style: TextStyle(color: Colors.grey[400])),
                  if (flashcard.partOfSpeech != null)
                    Text(
                      flashcard.partOfSpeech!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],

            // Examples
            if (flashcard.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Ví dụ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...flashcard.examples.map(
                    (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.grey[600])),
                      Expanded(
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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