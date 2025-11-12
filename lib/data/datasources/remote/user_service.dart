// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tìm user theo tên hoặc email
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff') // Prefix search cho tên
        .limit(10)
        .get();

    // Hoặc query email nếu không tìm thấy tên
    if (snapshot.docs.isEmpty) {
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: query)
          .limit(1)
          .get();
      // Convert sang UserModel...
    }

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()..['uid'] = doc.id))
        .toList();
  }

  // Thêm bạn bè (cập nhật mutual friends)
  Future<void> addFriend(String currentUid, String friendUid) async {
    // Cập nhật current user
    final currentRef = _firestore.collection('users').doc(currentUid);
    await currentRef.update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });

    // Cập nhật friend user
    final friendRef = _firestore.collection('users').doc(friendUid);
    await friendRef.update({
      'friends': FieldValue.arrayUnion([currentUid]),
    });

    // Tạo ChatRoom nếu chưa có
    final chatId = [currentUid, friendUid]..sort(); // Sắp xếp để ID unique
    final chatIdStr = chatId.join('_');
    final chatRef = _firestore.collection('chat_rooms').doc(chatIdStr);
    await chatRef.set({
      'id': chatIdStr,
      'participants': [currentUid, friendUid],
      'lastMessageAt': Timestamp.now(),
      'lastMessage': 'Bắt đầu chat!',
    }, SetOptions(merge: true));
  }
}