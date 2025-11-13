// lib/ui/widgets/flashcard_item.dart (assuming path)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../data/models/flashcard_model.dart';

class FlashcardItem extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback onTap;
  final VoidCallback onToggleMemorized;
  final VoidCallback onMoveToFolder;
  final VoidCallback onDelete;

  const FlashcardItem({
    Key? key,
    required this.flashcard,
    required this.onTap,
    required this.onToggleMemorized,
    required this.onMoveToFolder,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem> {
  static FlutterTts? _sharedTts;
  static String? _currentSpeaking;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    if (_sharedTts == null) {
      _sharedTts = FlutterTts();

      try {
        var languages = await _sharedTts!.getLanguages;
        if (languages.contains("en-US")) {
          await _sharedTts!.setLanguage("en-US");
        }

        await _sharedTts!.setSpeechRate(0.5);
        await _sharedTts!.setVolume(1.0);
        await _sharedTts!.setPitch(1.0);
        await _sharedTts!.awaitSpeakCompletion(true);

        _sharedTts!.setStartHandler(() {
          if (mounted && _currentSpeaking == widget.flashcard.id) {
            setState(() => _isSpeaking = true);
          }
        });

        _sharedTts!.setCompletionHandler(() {
          if (mounted && _currentSpeaking == widget.flashcard.id) {
            setState(() {
              _isSpeaking = false;
              _currentSpeaking = null;
            });
          }
        });

        _sharedTts!.setErrorHandler((msg) {
          if (mounted && _currentSpeaking == widget.flashcard.id) {
            setState(() {
              _isSpeaking = false;
              _currentSpeaking = null;
            });
          }
        });

        _sharedTts!.setCancelHandler(() {
          if (mounted && _currentSpeaking == widget.flashcard.id) {
            setState(() {
              _isSpeaking = false;
              _currentSpeaking = null;
            });
          }
        });
      } catch (e) {
        print('TTS initialization error: $e');
      }
    }
  }

  Future<void> _speak() async {
    if (_sharedTts == null) return;

    try {
      if (_currentSpeaking != null && _currentSpeaking != widget.flashcard.id) {
        await _sharedTts!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (_isSpeaking && _currentSpeaking == widget.flashcard.id) {
        await _sharedTts!.stop();
        setState(() {
          _isSpeaking = false;
          _currentSpeaking = null;
        });
        return;
      }

      _currentSpeaking = widget.flashcard.id;
      setState(() => _isSpeaking = true);

      var result = await _sharedTts!.speak(widget.flashcard.english);

      print('TTS result: $result for ${widget.flashcard.english}');

      if (mounted && _currentSpeaking == widget.flashcard.id) {
        setState(() {
          _isSpeaking = false;
          _currentSpeaking = null;
        });
      }
    } catch (e) {
      print('Speak error: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentSpeaking = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThisCardSpeaking = _isSpeaking && _currentSpeaking == widget.flashcard.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey.shade50,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.flashcard.isMemorized
                      ? Colors.green.shade400
                      : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.flashcard.vietnamese,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isThisCardSpeaking
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                      maxLines: 2, // NEW: Limit lines to prevent vertical overflow
                      overflow: TextOverflow.ellipsis, // NEW: Ellipsis if too long
                    ),
                    const SizedBox(height: 4), // Add small space for better layout
                    // FIXED: Wrap inner Row with Flexible children to prevent horizontal overflow
                    Row(
                      children: [
                        Flexible( // NEW: Flexible for english text
                          child: Text(
                            widget.flashcard.english,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: isThisCardSpeaking
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Ensure ellipsis
                          ),
                        ),
                        if (widget.flashcard.phonetic != null &&
                            widget.flashcard.phonetic!.isNotEmpty) ...[
                          const SizedBox(width: 4), // Reduce space
                          Flexible( // NEW: Flexible for phonetic
                            child: Text(
                              widget.flashcard.phonetic!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (widget.flashcard.partOfSpeech != null) ...[
                          const SizedBox(width: 4), // Reduce space
                          Flexible( // NEW: Flexible for partOfSpeech container
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, // Reduce padding
                                  vertical: 2
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.flashcard.partOfSpeech!,
                                style: TextStyle(
                                  fontSize: 11, // Slightly smaller
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis, // NEW: Ellipsis for chip text
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _speak,
                icon: Icon(
                  isThisCardSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                  color: isThisCardSpeaking ? Colors.blue : Colors.grey[600],
                  size: 24,
                ),
                tooltip: 'Phát âm',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}