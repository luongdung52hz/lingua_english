import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class HomeController extends GetxController {
  HomeController({required UserRepository repository})
    : _repository = repository;
  final UserRepository _repository;
  StreamSubscription<UserModel?>? _userSubscription;
  Future<void>? _refresh;
  final progressPercent = 0.0.obs;
  final completedLessons = 0.obs;
  final totalLessons = 0.obs;
  final score = 0.obs;
  final dailyCompleted = 0.obs;
  final targetDaily = 5.obs;
  final dailyStreak = 0.obs;
  final userName = ''.obs;
  final error = RxnString();
  String get userId => _repository.userId;

  @override
  void onInit() {
    super.onInit();
    _userSubscription = _repository.watchUser().listen(
      (user) {
        if (isClosed || user == null) return;
        progressPercent.value = user.progress;
        completedLessons.value = user.completedLessons;
        totalLessons.value = user.totalLessons;
        score.value = user.score;
        dailyCompleted.value = user.dailyCompleted;
        targetDaily.value = user.targetDaily;
        dailyStreak.value = user.dailyStreak;
        userName.value = user.name;
      },
      onError: (Object value) {
        if (!isClosed) error.value = value.toString();
      },
    );
    refresh();
  }

  // Repeated pull-to-refresh shares one request. The stream updates the UI.
  Future<void> refresh() =>
      _refresh ??= _prepare().whenComplete(() => _refresh = null);

  Future<void> _prepare() async {
    try {
      error.value = null;
      await _repository.prepareDashboard();
    } catch (value) {
      if (!isClosed) error.value = value.toString();
    }
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }
}
