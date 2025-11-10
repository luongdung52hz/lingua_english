import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/flashcard_controller.dart';
import 'widgets/move_to_folder_dialog.dart';
import 'package:flutter/services.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardController controller = Get.find<FlashcardController>();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late FlutterTts _flutterTts;
  bool _isFlipped = false;
  int _currentIndex = 0;
  List<Flashcard> _studyCards = [];
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _loadStudyCards();
    _flipController =
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _flipAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
    _initTts();
    _worker = ever(controller.flashcards, (_) => mounted ? _refreshStudyCards() : null);
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(text);
  }

  void _loadStudyCards() {
    _studyCards = controller.flashcards.where((f) => !f.isMemorized).toList()..shuffle();
    setState(() {});
  }

  void _refreshStudyCards() {
    final newCards = controller.flashcards.where((f) => !f.isMemorized).toList();
    if (_studyCards.length != newCards.length) {
      setState(() {
        _studyCards = newCards..shuffle();
        _currentIndex = 0;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _flutterTts.stop();
    _worker?.dispose();
    super.dispose();
  }

  void _flipCard() {
    _isFlipped ? _flipController.reverse() : _flipController.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard(bool memorized) async {
    final card = _studyCards[_currentIndex];
    await controller.toggleMemorized(card.id!, memorized);
    if (_isFlipped) {
      _flipController.reverse();
      _isFlipped = false;
    }
    setState(() {
      _currentIndex < _studyCards.length - 1 ? _currentIndex++ : _showCompletion();
    });
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: const Text('Bạn đã học xong tất cả flashcard chưa thuộc.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Về danh sách')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadStudyCards();
              _currentIndex = 0;
              _isFlipped = false;
              _flipController.reset();
            },
            child: const Text('Học lại'),
          ),
        ],
      ),
    );
  }

  void _handleMenu(String value) async {
    final card = _studyCards[_currentIndex];
    switch (value) {
      case 'toggle':
        await controller.toggleMemorized(card.id!, !card.isMemorized);
        if (!card.isMemorized) _nextCard(true);
        break;
      case 'move':
        showDialog(
            context: context,
            builder: (_) => MoveToFolderDialog(
              flashcard: card,
              onMove: (id) async {
                await controller.moveToFolder(card.id!, id);
                Navigator.pop(context);
                setState(() => _studyCards.removeWhere((c) => c.id == card.id));
                if (_currentIndex >= _studyCards.length && _studyCards.isNotEmpty) {
                  _currentIndex = _studyCards.length - 1;
                }
              },
            ));
        break;
      case 'delete':
        if (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa?'),
            content: Text('Xóa "${card.english}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
            false) {
          await controller.deleteFlashcard(card.id!);
          setState(() {
            _studyCards.removeAt(_currentIndex);
            if (_studyCards.isEmpty) {
              _showCompletion();
            } else if (_currentIndex >= _studyCards.length) {
              _currentIndex = _studyCards.length - 1;
            }
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_studyCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Học Flashcard'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
            const SizedBox(height: 16),
            const Text('Không còn thẻ nào cần học!', style: TextStyle(fontSize: 18)),
            Text('Tất cả đã được đánh dấu "đã thuộc"',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
          ]),
        ),
      );
    }

    final card = _studyCards[_currentIndex];
    final progress = (_currentIndex + 1) / _studyCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Thẻ ${_currentIndex + 1}/${_studyCards.length}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white)),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                        card.isMemorized ? Icons.cancel : Icons.check_circle,
                        color: card.isMemorized ? Colors.orange : Colors.green),
                    const SizedBox(width: 8),
                    Text(card.isMemorized ? 'Chưa thuộc' : 'Đã thuộc')
                  ])),
              const PopupMenuItem(
                  value: 'move',
                  child: Row(children: [
                    Icon(Icons.drive_file_move, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chuyển thư mục')
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa')
                  ])),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          )
        ],
      ),
      body: GestureDetector(
        onTap: _flipCard,
        onDoubleTap: () => _speak(card.english),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -100) {
              if (_currentIndex < _studyCards.length - 1) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex++;
                  _isFlipped = false;
                  _flipController.reset();
                });
              } else {
                _showCompletion();
              }
            } else if (details.primaryVelocity! > 100) {
              _previousCard();
            }
          }
        },
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
                                ? FlashcardCard(
                              flashcard: card,
                              isFront: true,
                              onSpeak: () => _speak(card.english),
                            )
                                : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: FlashcardCard(
                                flashcard: card,
                                isFront: false,
                                onSpeak: () => _speak(card.english),
                              ),
                            ));
                      }))),
          if (_isFlipped)
            _buildBottomButtons()
          else
            Container(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.touch_app, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('Nhấn để lật thẻ • Vuốt để đổi thẻ ',
                      style: TextStyle(color: Colors.grey[600]))
                ])),
        ]),
      ),
    );
  }

  Widget _buildBottomButtons() => Container(
    padding: const EdgeInsets.all(24),
    color: Colors.white,
    child: Column(children: [
      const Text('Bạn đã thuộc từ này chưa?',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: OutlinedButton.icon(
                onPressed: () => _nextCard(false),
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Chưa thuộc',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))))),
        const SizedBox(width: 12),
        Expanded(
            child: ElevatedButton.icon(
                onPressed: () => _nextCard(true),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Đã thuộc',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))))),
      ]),
    ]),
  );
}

class FlashcardCard extends StatelessWidget {
  final Flashcard flashcard;
  final bool isFront;
  final VoidCallback onSpeak;

  const FlashcardCard(
      {Key? key,
        required this.flashcard,
        required this.isFront,
        required this.onSpeak})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFront
        ? _buildFront(flashcard)
        : _buildBack(flashcard, onSpeak);
  }

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

  Widget _buildBack(Flashcard f, VoidCallback onSpeak) => Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ]),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
            onTap: onSpeak,
            child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.volume_up, color: Colors.green, size: 28))),
        const SizedBox(height: 8),
        Text(f.english,
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center),
        if (f.phonetic?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(f.phonetic!,
              style: const TextStyle(
                  fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic))
        ],
        if (f.examples.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(16),
              decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ví dụ:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...f.examples.take(2).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $e',
                        style: const TextStyle(
                            fontSize: 13, fontStyle: FontStyle.italic))))
              ]))
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
