import '../../data/repositories/user_repository.dart';

import '../../data/models/user_model.dart';
import 'base_controller.dart';

class UserController extends BaseController {
  UserController({required UserRepository repository})
    : _repository = repository;
  final UserRepository _repository;
  Future<UserModel?> getUserByUid(String uid) async {
    setLoading(true);
    try {
      return await _repository.getUserByUid(uid);
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}
