import 'package:flutter/material.dart';
import '../../../data/models/flashcard_model.dart';

class FlashcardCard extends StatelessWidget {
  final Flashcard flashcard;
  final bool isFront;
  final VoidCallback? onSpeak;

  const FlashcardCard({
    Key? key,
    required this.flashcard,
    required this.isFront,
    this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFront ? _buildFront() : _buildBack();
  }

  Widget _buildFront() => Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          flashcard.vietnamese,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Tiếng Việt',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _buildBack() => Container(
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ],
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onSpeak,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up, color: Colors.green, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            flashcard.english,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          if (flashcard.phonetic != null && flashcard.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              flashcard.phonetic!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (flashcard.examples.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ví dụ:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...flashcard.examples.take(2).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $e',
                      style: const TextStyle(
                          fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'English',
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
