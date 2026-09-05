import '../../data/models/lesson_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';

class AdminController {
  AdminController({
    required AdminRepository repository,
    required AuthRepository auth,
  }) : _repository = repository,
       _auth = auth {
    lessonsStream = repository.watchLessons();
  }
  final AdminRepository _repository;
  final AuthRepository _auth;
  late final Stream<List<LessonModel>> lessonsStream;
  Future<void> addLesson(LessonModel lesson) => _repository.addLesson(lesson);
  Future<void> updateLesson(String id, Map<String, dynamic> fields) =>
      _repository.updateLesson(id, fields);
  Future<void> deleteLesson(String id) => _repository.deleteLesson(id);
  Future<void> logout() => _auth.signOut();
}
