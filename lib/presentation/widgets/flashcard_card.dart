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
    // Fixed dimensions for card
    final screenSize = MediaQuery.of(context).size;
    final cardHeight = 500.0; // 60% of screen height
     final cardWidth = 300.0;
    // final cardHeight = screenSize.height * 0.6; // 60% of screen height
    // final cardWidth = screenSize.width * 0.85; // 85% of screen width

    return Center(
      child: Container(
        height: cardHeight,
        width: cardWidth,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFront ? Colors.blue[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: isFront ? _buildFront() : _buildBack(),
      ),
    );
  }

  Widget _buildFront() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 1),
        // Vietnamese text - centered and scrollable if too long
        Flexible(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                flashcard.vietnamese,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        // Language badge at bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Tiếng Việt',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBack() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Speaker button at top
        GestureDetector(
          onTap: onSpeak,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up,
              color: Colors.green,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Scrollable content area with fixed height
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // English text
                Text(
                  flashcard.english,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Phonetic
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

                // Examples
                if (flashcard.examples.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ví dụ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...flashcard.examples.take(2).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $e',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Language badge at bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'English',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}