// lib/data/models/flashcard_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String? id;
  final String vietnamese;
  final String english;
  final String? phonetic;
  final String? partOfSpeech;
  final List<String> examples;
  final String? imageUrl;
  final bool isMemorized;
  final DateTime createdAt;
  final DateTime lastReviewed;
  final int reviewCount;
  final String folderId; // ✅ NEW: Folder reference

  Flashcard({
    this.id,
    required this.vietnamese,
    required this.english,
    this.phonetic,
    this.partOfSpeech,
    this.examples = const [],
    this.imageUrl,
    this.isMemorized = false,
    DateTime? createdAt,
    DateTime? lastReviewed,
    this.reviewCount = 0,
    this.folderId = 'default', // ✅ NEW: Default folder
  })  : createdAt = createdAt ?? DateTime.now(),
        lastReviewed = lastReviewed ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'vietnamese': vietnamese,
      'english': english,
      'phonetic': phonetic,
      'partOfSpeech': partOfSpeech,
      'examples': examples,
      'imageUrl': imageUrl,
      'isMemorized': isMemorized,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReviewed': Timestamp.fromDate(lastReviewed),
      'reviewCount': reviewCount,
      'folderId': folderId, // ✅ NEW
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json, String id) {
    return Flashcard(
      id: id,
      vietnamese: json['vietnamese'] ?? '',
      english: json['english'] ?? '',
      phonetic: json['phonetic'],
      partOfSpeech: json['partOfSpeech'],
      examples: List<String>.from(json['examples'] ?? []),
      imageUrl: json['imageUrl'],
      isMemorized: json['isMemorized'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReviewed: (json['lastReviewed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCount: json['reviewCount'] ?? 0,
      folderId: json['folderId'] ?? 'default', // ✅ NEW
    );
  }

  Flashcard copyWith({
    String? id,
    String? vietnamese,
    String? english,
    String? phonetic,
    String? partOfSpeech,
    List<String>? examples,
    String? imageUrl,
    bool? isMemorized,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    String? folderId, // ✅ NEW
  }) {
    return Flashcard(
      id: id ?? this.id,
      vietnamese: vietnamese ?? this.vietnamese,
      english: english ?? this.english,
      phonetic: phonetic ?? this.phonetic,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      examples: examples ?? this.examples,
      imageUrl: imageUrl ?? this.imageUrl,
      isMemorized: isMemorized ?? this.isMemorized,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      folderId: folderId ?? this.folderId, // ✅ NEW
    );
  }
}

// ✅ NEW: Folder Model
class FlashcardFolder {
  final String? id;
  final String name;
  final String? description;
  final String icon; // Emoji icon
  final String color; // Hex color code
  final DateTime createdAt;
  final int cardCount; // Cached count for performance

  FlashcardFolder({
    this.id,
    required this.name,
    this.description,
    this.icon = '📚',
    this.color = '#9C27B0',
    DateTime? createdAt,
    this.cardCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'cardCount': cardCount,
    };
  }

  factory FlashcardFolder.fromJson(Map<String, dynamic> json, String id) {
    return FlashcardFolder(
      id: id,
      name: json['name'] ?? 'Unnamed',
      description: json['description'],
      icon: json['icon'] ?? '📚',
      color: json['color'] ?? '#9C27B0',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cardCount: json['cardCount'] ?? 0,
    );
  }

  FlashcardFolder copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    DateTime? createdAt,
    int? cardCount,
  }) {
    return FlashcardFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      cardCount: cardCount ?? this.cardCount,
    );
  }
}