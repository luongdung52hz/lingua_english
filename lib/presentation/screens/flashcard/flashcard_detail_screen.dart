// lib/presentation/screens/flashcard/flashcard_detail_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/flashcard_controller.dart';
import 'widgets/move_to_folder_dialog.dart';

class FlashcardDetailScreen extends StatefulWidget {
  final String id;
  const FlashcardDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardController controller = Get.find<FlashcardController>();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late FlutterTts _flutterTts;
  bool _isFlipped = false;
  late Flashcard currentCard;

  @override
  void initState() {
    super.initState();
    _loadCard();
    _flipController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _flipAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
    _initTts();
  }

  void _loadCard() {
    currentCard = controller.flashcards.firstWhere((c) => c.id == widget.id);
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _flipCard() {
    _isFlipped ? _flipController.reverse() : _flipController.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _handleMenu(String action) async {
    switch (action) {
      case 'toggle':
        await controller.toggleMemorized(currentCard.id!, !currentCard.isMemorized);
        setState(() {
          currentCard = currentCard.copyWith(isMemorized: !currentCard.isMemorized);
        });
        HapticFeedback.mediumImpact();
        Get.snackbar(
          'Cập nhật',
          currentCard.isMemorized ? 'Đã đánh dấu là ĐÃ THUỘC' : 'Đã đánh dấu là CHƯA THUỘC',
          backgroundColor: Colors.white,
          colorText: Colors.black87,
        );
        break;

      case 'move':
        showDialog(
          context: context,
          builder: (_) => MoveToFolderDialog(
            flashcard: currentCard,
            onMove: (folderId) async {
              await controller.moveToFolder(currentCard.id!, folderId);
              Navigator.pop(context);
              Get.snackbar('Thành công', 'Đã chuyển thẻ sang thư mục khác!',
                  backgroundColor: Colors.green[100], colorText: Colors.black);
            },
          ),
        );
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa thẻ này?'),
            content: Text('Bạn có chắc muốn xóa "${currentCard.english}" không?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          await controller.deleteFlashcard(currentCard.id!);
          if (context.mounted) context.pop();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlashCard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    currentCard.isMemorized ? Icons.cancel : Icons.check_circle,
                    color: currentCard.isMemorized ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(currentCard.isMemorized ? 'Đánh dấu chưa thuộc' : 'Đánh dấu đã thuộc'),
                ]),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(children: [
                  Icon(Icons.drive_file_move, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Chuyển thư mục'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa thẻ'),
                ]),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _flipCard,
        onDoubleTap: () => _speak(currentCard.english),
        child: Column(children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isFront = angle < pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isFront
                        ? _buildFront(currentCard)
                        : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildBack(currentCard)),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                // BoxShadow(
                //     color: Colors.black.withOpacity(0.1),
                //     blurRadius: 10,
                //     offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.touch_app, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Nhấn để lật thẻ ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }

  // ======= MẶT TRƯỚC =======
  Widget _buildFront(Flashcard card) => Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(card.vietnamese,
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 32),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Text('Tiếng Việt',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
    ]),
  );

  // ======= MẶT SAU =======
  Widget _buildBack(Flashcard f) => Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
      ],
    ),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () => _speak(f.english),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.volume_up, color: Colors.green, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(f.english,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center),
        if (f.phonetic != null) ...[
          const SizedBox(height: 12),
          Text(f.phonetic!,
              style:
              const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic))
        ],
        if (f.examples.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ví dụ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...f.examples.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $e',
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))))
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration:
            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('English',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      ]),
    ),
  );
}
