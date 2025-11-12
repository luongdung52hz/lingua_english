// lib/controllers/user_controller.dart (mới hoặc extend)
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';
import 'base_controller.dart';

class UserController extends BaseController {
  Future<UserModel?> getUserByUid(String uid) async {
    setLoading(true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromJson(doc.data()!) : null;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}