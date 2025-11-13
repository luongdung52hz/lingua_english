// widgets/generic_info_card.dart - Updated with optional status bar (Positioned overlay)

import 'package:flutter/material.dart';
import '../../resources/styles/colors.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle; // Optional description
  final List<IconTextPair>? infoPairs; // Flexible bottom info row (e.g., time, difficulty)
  final bool isCompleted;
  final int? score; // Optional score for badge
  final VoidCallback? onTap;
  final Color? gradientStartColor; // Customizable gradient
  final Color? gradientEndColor;
  final Color? badgeColor; // Badge background if completed
  final Widget? trailing; // Optional trailing widget (e.g., TTS button)
  final Color? statusBarColor; // NEW: Optional status bar color (if provided, render Positioned bar)
  final double? statusBarHeight; // NEW: Status bar height (default 30)
  final double statusBarTop; // NEW: Top position for status bar (default 12 for centering)

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.infoPairs, // e.g., [IconTextPair(Icons.access_time, '10 phút'), IconTextPair(Icons.stars, '3/5')]
    this.isCompleted = false,
    this.score,
    this.onTap,
    this.gradientStartColor,
    this.gradientEndColor,
    this.badgeColor,
    this.trailing,
    this.statusBarColor, // NEW: If non-null, show left status bar
    this.statusBarHeight,
    this.statusBarTop = 12.0, // NEW: Position from top
  });

  @override
  Widget build(BuildContext context) {
    final startColor = gradientStartColor ?? (isCompleted ? Colors.green.shade50 : Colors.grey.shade50);
    final endColor = gradientEndColor ?? (isCompleted ? Colors.green.shade100 : Colors.grey.shade100);
    final effectiveStatusBarHeight = statusBarHeight ?? 30.0;

    // NEW: Conditionally use Stack if status bar is provided
    final useStack = statusBarColor != null;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (infoPairs != null && infoPairs!.isNotEmpty)
                  _InfoRow(infoPairs: infoPairs!),
              ],
            ),
          ),
          if (isCompleted && score != null) ...[
            const SizedBox(width: 8),
            _ScoreBadge(
              score: score!,
              badgeColor: badgeColor ?? Colors.green.shade600,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    // NEW: Wrap in Stack only if status bar is enabled
    if (useStack) {
      cardContent = Stack(
        children: [
          cardContent,
          Positioned(
            left: 0,
            top: statusBarTop,
            child: Container(
              width: 8,
              height: effectiveStatusBarHeight,
              decoration: BoxDecoration(
                color: statusBarColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final List<IconTextPair> infoPairs;

  const _InfoRow({
    required this.infoPairs,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Horizontal scroll if many pairs
      scrollDirection: Axis.horizontal,
      child: Row(
        children: infoPairs.map((pair) => Padding(
          padding: const EdgeInsets.only(right: 16), // Space between pairs
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pair.icon,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                pair.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

/// Reusable: Score badge for completed items
class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color badgeColor;

  const _ScoreBadge({
    required this.score,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Helper class for icon-text pairs (reusable across cards)
class IconTextPair {
  final IconData icon;
  final String label;

  const IconTextPair(this.icon, this.label);
}