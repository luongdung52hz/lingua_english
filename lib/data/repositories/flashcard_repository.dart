// lib/data/repositories/flashcard_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard_model.dart';

class FlashcardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _userId => _auth.currentUser?.uid;

  // ============================================
  // FLASHCARD OPERATIONS
  // ============================================
  /// Get user's flashcard collection reference
  CollectionReference _getFlashcardsCollection() {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('flashcards');
  }

  /// Stream all flashcards
  Stream<List<Flashcard>> getFlashcards() {
    return _getFlashcardsCollection()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Stream flashcards by folder
  Stream<List<Flashcard>> getFlashcardsByFolder(String folderId) {
    return _getFlashcardsCollection()
        .where('folderId', isEqualTo: folderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Stream flashcards to review (not memorized)
  Stream<List<Flashcard>> getFlashcardsToReview() {
    return _getFlashcardsCollection()
        .where('isMemorized', isEqualTo: false)
        .orderBy('lastReviewed')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Stream flashcards to review by folder
  Stream<List<Flashcard>> getFlashcardsToReviewByFolder(String folderId) {
    return _getFlashcardsCollection()
        .where('folderId', isEqualTo: folderId)
        .where('isMemorized', isEqualTo: false)
        .orderBy('lastReviewed')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Search flashcards
  Stream<List<Flashcard>> searchFlashcards(String query) {
    return _getFlashcardsCollection().snapshots().map((snapshot) {
      final allCards = snapshot.docs
          .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      return allCards
          .where((card) =>
      card.vietnamese.toLowerCase().contains(query.toLowerCase()) ||
          card.english.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Create flashcard
  Future<void> createFlashcard(Flashcard flashcard) async {
    await _getFlashcardsCollection().add(flashcard.toJson());

    // Update folder card count
    await _updateFolderCardCount(flashcard.folderId);
  }

  /// Update flashcard
  Future<void> updateFlashcard(Flashcard flashcard) async {
    if (flashcard.id == null) throw Exception('Flashcard ID is required');
    await _getFlashcardsCollection().doc(flashcard.id).update(flashcard.toJson());
  }

  /// Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    // Get card to know which folder to update
    final doc = await _getFlashcardsCollection().doc(flashcardId).get();
    final data = doc.data() as Map<String, dynamic>?;
    final folderId = data?['folderId'] as String?;

    await _getFlashcardsCollection().doc(flashcardId).delete();

    // Update folder count
    if (folderId != null) {
      await _updateFolderCardCount(folderId);
    }
  }

  /// Mark as memorized
  Future<void> markAsMemorized(String flashcardId, bool isMemorized) async {
    await _getFlashcardsCollection().doc(flashcardId).update({
      'isMemorized': isMemorized,
      'lastReviewed': Timestamp.now(),
      'reviewCount': FieldValue.increment(1),
    });
  }

  /// Reset all flashcards (mark as not memorized)
  Future<void> resetAllFlashcards() async {
    final snapshot = await _getFlashcardsCollection().get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isMemorized': false,
        'reviewCount': 0,
      });
    }
    await batch.commit();
  }

  /// Move flashcard to another folder
  Future<void> moveToFolder(String flashcardId, String newFolderId) async {
    // Get old folder ID
    final doc = await _getFlashcardsCollection().doc(flashcardId).get();
    final data = doc.data() as Map<String, dynamic>?;
    final oldFolderId = data?['folderId'] as String?;

    // Update flashcard
    await _getFlashcardsCollection().doc(flashcardId).update({
      'folderId': newFolderId,
    });

    // Update both folder counts
    if (oldFolderId != null) {
      await _updateFolderCardCount(oldFolderId);
    }
    await _updateFolderCardCount(newFolderId);
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    final snapshot = await _getFlashcardsCollection().get();
    final cards = snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    return {
      'total': cards.length,
      'memorized': cards.where((c) => c.isMemorized).length,
      'toReview': cards.where((c) => !c.isMemorized).length,
    };
  }

  /// Get statistics by folder
  Future<Map<String, int>> getStatisticsByFolder(String folderId) async {
    final snapshot = await _getFlashcardsCollection()
        .where('folderId', isEqualTo: folderId)
        .get();

    final cards = snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    return {
      'total': cards.length,
      'memorized': cards.where((c) => c.isMemorized).length,
      'toReview': cards.where((c) => !c.isMemorized).length,
    };
  }

  // ============================================
  // FOLDER OPERATIONS
  // ============================================
  /// Get user's folder collection reference
  CollectionReference _getFoldersCollection() {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('folders');
  }

  /// Stream all folders
  Stream<List<FlashcardFolder>> getFolders() {
    return _getFoldersCollection()
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FlashcardFolder.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Create folder
  Future<String> createFolder(FlashcardFolder folder) async {
    final docRef = await _getFoldersCollection().add(folder.toJson());
    return docRef.id;
  }

  /// Update folder
  Future<void> updateFolder(FlashcardFolder folder) async {
    if (folder.id == null) throw Exception('Folder ID is required');
    await _getFoldersCollection().doc(folder.id).update(folder.toJson());
  }

  /// Delete folder (and optionally move cards to default)
  Future<void> deleteFolder(String folderId, {bool moveToDefault = true}) async {
    if (folderId == 'default') {
      throw Exception('Cannot delete default folder');
    }
    if (moveToDefault) {
      // Move all cards to default folder
      final cards = await _getFlashcardsCollection()
          .where('folderId', isEqualTo: folderId)
          .get();

      final batch = _firestore.batch();
      for (var doc in cards.docs) {
        batch.update(doc.reference, {'folderId': 'default'});
      }
      await batch.commit();

      // Update default folder count
      await _updateFolderCardCount('default');
    } else {
      // Delete all cards in folder
      final cards = await _getFlashcardsCollection()
          .where('folderId', isEqualTo: folderId)
          .get();

      final batch = _firestore.batch();
      for (var doc in cards.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // Delete folder
    await _getFoldersCollection().doc(folderId).delete();
  }

  /// Update folder card count
  Future<void> _updateFolderCardCount(String folderId) async {
    final count = await _getFlashcardsCollection()
        .where('folderId', isEqualTo: folderId)
        .count()
        .get();
    await _getFoldersCollection().doc(folderId).update({
      'cardCount': count.count,
    });
  }

  /// Initialize default folder if not exists
  Future<void> initializeDefaultFolder() async {
    try {
      final doc = await _getFoldersCollection().doc('default').get();

      if (!doc.exists) {
        await _getFoldersCollection().doc('default').set(
          FlashcardFolder(
            id: 'default',
            name: 'Tất cả',
            description: 'Thư mục mặc định chứa tất cả flashcard',
            icon: '📚',
            color: '#9C27B0',
          ).toJson(),
        );
      }
    } catch (e) {
      print('Error initializing default folder: $e');
    }
  }
}