// widgets/generic_info_card.dart - UPDATED: Reduced paddings and margins for tighter spacing

import 'package:flutter/material.dart';
import 'package:learn_english/resources/styles/text_styles.dart';
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
  final Widget? leading; // Optional leading widget (e.g., thumbnail image)
  final Color? statusBarColor; // Optional status bar color (if provided, render Positioned bar)
  final double? statusBarHeight; // Status bar height (default 30)
  final double statusBarTop; // Top position for status bar (default 12 for centering)
  final bool verticalLayout; // For grid views (Column layout with full-width leading on top)
  final double? leadingAspectRatio; // Aspect ratio for leading in vertical layout (default 16/9)
  final Widget? overlay; // Positioned overlay on leading (e.g., "Next" badge in vertical)
  final TextStyle? subtitleStyle; // NEW: Custom subtitle style (overrides default)

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
    this.leading, // Support for leading (e.g., image thumbnail)
    this.statusBarColor, // If non-null, show left status bar
    this.statusBarHeight,
    this.statusBarTop = 12.0, // Position from top
    this.verticalLayout = false, // Default horizontal (Row) for list
    this.leadingAspectRatio,
    this.overlay,
    this.subtitleStyle, // NEW: For custom font size/color etc.
  });

  @override
  Widget build(BuildContext context) {
    final startColor = gradientStartColor ?? (isCompleted ? Colors.green.shade50 : Colors.grey.shade50);
    final endColor = gradientEndColor ?? (isCompleted ? Colors.green.shade100 : Colors.grey.shade100);
    final effectiveStatusBarHeight = statusBarHeight ?? 30.0;

    // Conditionally use Stack if status bar is provided
    final useStack = statusBarColor != null;

    // Text style helpers
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 60,
      color: AppColors.primary,
    );
    final defaultSubtitleStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey.shade600,
      height: 1.4,
    );

    Widget innerContent;
    if (verticalLayout) {
      // VERTICAL LAYOUT: For grid - full-width leading on top, text below
      innerContent = Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8), // Reduced from 10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading with aspect ratio and overlay
            Stack(
              children: [
                if (leadingAspectRatio != null && leading != null)
                  AspectRatio(
                    aspectRatio: leadingAspectRatio!,
                    child: leading!,
                  )
                else if (leading != null)
                  leading!
                else
                  const SizedBox.shrink(),
                if (overlay != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: overlay!,
                  ),
              ],
            ),
            const SizedBox(height: 8), // Reduced from 12
            // Text content
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title, // Smaller for grid
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1, // Single line for grid
                overflow: TextOverflow.ellipsis,
                style: (subtitleStyle ?? defaultSubtitleStyle).copyWith(fontSize: 11),
              ),
            ],
            const SizedBox(height: 6), // Reduced from 8
            if (infoPairs != null && infoPairs!.isNotEmpty)
              _InfoRow(infoPairs: infoPairs!),
            if (trailing != null) ...[
              const SizedBox(height: 6), // Reduced from 8
              trailing!,
            ],
          ],
        ),
      );
    } else {
      // HORIZONTAL LAYOUT: Original Row for list views
      innerContent = Padding(
        padding: const EdgeInsets.all(8), // Reduced from 10
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8), // Reduced from 12
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2, // Allow multi-line title with ellipsis
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: subtitleStyle ?? defaultSubtitleStyle, // Use custom if provided
                    ),
                  ],
                  const SizedBox(height: 6), // Reduced from 8
                  if (infoPairs != null && infoPairs!.isNotEmpty)
                    _InfoRow(infoPairs: infoPairs!),
                ],
              ),
            ),
            if (isCompleted && score != null) ...[
              const SizedBox(width: 6), // Reduced from 8
              _ScoreBadge(
                score: score!,
                badgeColor: badgeColor ?? Colors.green.shade600,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 6), // Reduced from 8
              trailing!,
            ],
          ],
        ),
      );
    }

    // Create Container with innerContent as child (no self-reference)
    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: innerContent,
    );

    // Wrap in Stack only if status bar is enabled
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced from horizontal 11, vertical 6
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
          padding: const EdgeInsets.only(right: 12), // Reduced from 16
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