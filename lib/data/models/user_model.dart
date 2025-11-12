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
  final List<String> friends;
  final List<String> quizInvites;

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
    this.friends = const [],
    this.quizInvites = const [],
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
      dailyCompleted: json['dailyCompleted'] ?? 0,
      targetDaily: json['targetDaily'] ?? 5,
      dailyStreak: json['dailyStreak'] ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
      friends: List<String>.from(json['friends'] ?? []),
      quizInvites: List<String>.from(json['quizInvites'] ?? []),
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
    'dailyCompleted': dailyCompleted,
    'targetDaily': targetDaily,
    'dailyStreak': dailyStreak,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'friends': friends,
    'quizInvites': quizInvites,
  };

  // Phương thức helper: Thêm bạn bè (tạo instance mới với friends cập nhật)
  UserModel addFriend(String friendUid) {
    final updatedFriends = List<String>.from(friends)..add(friendUid);
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      level: level,
      progress: progress,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      score: score,
      dailyCompleted: dailyCompleted,
      targetDaily: targetDaily,
      dailyStreak: dailyStreak,
      createdAt: createdAt,
      updatedAt: updatedAt,
      friends: updatedFriends,
      quizInvites: quizInvites,
    );
  }

  // Phương thức helper: Gửi lời mời quiz (tạo instance mới với quizInvites cập nhật)
  UserModel sendQuizInvite(String inviteUid) {
    final updatedInvites = List<String>.from(quizInvites)..add(inviteUid);
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      level: level,
      progress: progress,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      score: score,
      dailyCompleted: dailyCompleted,
      targetDaily: targetDaily,
      dailyStreak: dailyStreak,
      createdAt: createdAt,
      updatedAt: updatedAt,
      friends: friends,
      quizInvites: updatedInvites,
    );
  }

  // Optional: Phương thức copyWith để dễ dàng cập nhật bất kỳ trường nào (pattern tốt cho immutable models)
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? level,
    double? progress,
    int? completedLessons,
    int? totalLessons,
    int? score,
    int? dailyCompleted,
    int? targetDaily,
    int? dailyStreak,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<String>? friends,
    List<String>? quizInvites,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
      score: score ?? this.score,
      dailyCompleted: dailyCompleted ?? this.dailyCompleted,
      targetDaily: targetDaily ?? this.targetDaily,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      friends: friends ?? this.friends,
      quizInvites: quizInvites ?? this.quizInvites,
    );
  }
}