// lib/controllers/friend_controller.dart
import 'package:flutter/material.dart';
import '../../data/datasources/remote/user_service.dart';
import '../../data/models/user_model.dart';

import 'base_controller.dart';

class FriendController extends BaseController {
  final UserService _userService = UserService();
  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;

  // Tìm kiếm bạn bè
  Future<void> searchUsers(String query) async {
    setLoading(true);
    clearError();
    try {
      _searchResults = await _userService.searchUsers(query);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Thêm bạn bè
  Future<void> addFriend(String currentUid, UserModel friend) async {
    setLoading(true);
    try {
      await _userService.addFriend(currentUid, friend.uid);
      // Cập nhật local state nếu cần (e.g., remove from search results)
      _searchResults.removeWhere((u) => u.uid == friend.uid);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}