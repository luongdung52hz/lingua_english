// lib/data/services/firestore_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../demo/lesson_demo_data.dart';
import '../../models/lesson_model.dart';

class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload tất cả lessons lên Firestore (chỉ chạy 1 lần)
  Future<void> seedLessons() async {
    try {
      final lessons = LessonDemoData.getAllLessons();

      print('📤 Starting upload ${lessons.length} lessons...');

      // Dùng batch để upload nhanh hơn (tối đa 500 docs/batch)
      final batch = _firestore.batch();

      for (var lesson in lessons) {
        final docRef = _firestore.collection('lessons').doc(lesson.id);
        batch.set(docRef, {
          ...lesson.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✓ Prepared: ${lesson.title}');
      }

      await batch.commit();
      print('✅ Successfully uploaded ${lessons.length} lessons!');

    } catch (e) {
      print('❌ Error uploading lessons: $e');
      rethrow;
    }
  }

  /// Upload 1 lesson cụ thể (để update)
  Future<void> uploadSingleLesson(LessonModel lesson) async {
    try {
      await _firestore.collection('lessons').doc(lesson.id).set({
        ...lesson.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Updated lesson: ${lesson.title}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Xóa tất cả lessons (để test lại)
  Future<void> clearAllLessons() async {
    try {
      final snapshot = await _firestore.collection('lessons').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🗑️ Cleared ${snapshot.docs.length} lessons');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Kiểm tra số lượng lessons trên Firestore
  Future<void> checkLessonsCount() async {
    final snapshot = await _firestore.collection('lessons').get();
    print('📊 Total lessons on Firestore: ${snapshot.docs.length}');

    // Group by level
    final byLevel = <String, int>{};
    for (var doc in snapshot.docs) {
      final level = doc.data()['level'] as String;
      byLevel[level] = (byLevel[level] ?? 0) + 1;
    }
    print('By level: $byLevel');
  }
}