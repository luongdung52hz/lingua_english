// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String level; // e.g., "A1"
  final double progress; // 0-100
  final int completedLessons; // Tổng bài học
  final int totalLessons; // Tổng bài available
  final int score; // Điểm số
  final int dailyCompleted; // Số bài hoàn thành hôm nay
  final int targetDaily; // Số bài cần làm/ngày (daily goal)
  final int dailyStreak; // Số ngày streak
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.level,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.score,
    required this.dailyCompleted,
    required this.targetDaily,
    required this.dailyStreak,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore Map to UserModel (deserialization)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      level: json['level'] ?? 'A1',
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 5,
      score: json['score'] ?? 0,
      dailyCompleted: json['dailyCompleted'] ?? 0, // Thêm getter
      targetDaily: json['targetDaily'] ?? 5, // Thêm getter
      dailyStreak: json['dailyStreak'] ?? 0, // Thêm getter
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
    );
  }

  // To Map for Firestore (serialization)
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'level': level,
    'progress': progress,
    'completedLessons': completedLessons,
    'totalLessons': totalLessons,
    'score': score,
    'dailyCompleted': dailyCompleted, // Thêm param
    'targetDaily': targetDaily, // Thêm param
    'dailyStreak': dailyStreak, // Thêm param
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}