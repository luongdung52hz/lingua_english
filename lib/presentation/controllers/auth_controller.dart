import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../app/routes/route_names.dart';

/// Owns session routing state. Firebase and preferences are injected at startup.
class AuthController extends ChangeNotifier {
  AuthController({
    required Stream<String?> userIds,
    required Future<bool> Function(String) loadAdmin,
    required Future<void> Function() resetControllers,
    required Future<void> Function() saveOnboarding,
    required bool hasSeenOnboarding,
  }) : _loadAdmin = loadAdmin,
       _resetControllers = resetControllers,
       _saveOnboarding = saveOnboarding,
       _hasSeenOnboarding = hasSeenOnboarding {
    _subscription = userIds.distinct().listen(
      _setUser,
      onError: (Object error) {
        _setUser(null);
      },
    );
  }

  final Future<bool> Function(String) _loadAdmin;
  final Future<void> Function() _resetControllers;
  final Future<void> Function() _saveOnboarding;
  late final StreamSubscription<String?> _subscription;
  bool _hasSeenOnboarding;
  bool _ready = false;
  bool _isAdmin = false;
  bool _disposed = false;
  int _generation = 0;
  String? _uid;
  Future<void> _resetQueue = Future<void>.value();

  String? get userId => _uid;
  bool get isReady => _ready;
  bool get isAdmin => _isAdmin;

  Future<void> _setUser(String? uid) async {
    final generation = ++_generation;
    _ready = false;
    _uid = uid;
    _isAdmin = false;
    notifyListeners();
    // Serialize disposal when auth changes rapidly (A -> signed out -> B).
    final reset = _resetQueue = _resetQueue.then((_) => _resetControllers());
    await reset;
    if (_disposed || generation != _generation) return;
    var isAdmin = false;
    try {
      isAdmin = uid != null && await _loadAdmin(uid);
    } catch (_) {
      // A failed role read must never grant admin access.
      isAdmin = false;
    }
    if (_disposed || generation != _generation) return;
    _isAdmin = isAdmin;
    _ready = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _saveOnboarding();
    if (_disposed) return;
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  String? redirect(String location) {
    if (!_ready) return location == Routes.splash ? null : Routes.splash;
    final authRoute = [
      Routes.login,
      Routes.register,
      Routes.forgotPassword,
      Routes.onboarding,
    ].contains(location);
    if (_uid == null) {
      if (authRoute) return null;
      return _hasSeenOnboarding ? Routes.login : Routes.onboarding;
    }
    if (authRoute || location == Routes.splash) {
      return _isAdmin ? Routes.admin : Routes.home;
    }
    if (_isAdmin && location == Routes.home) return Routes.admin;
    if (!_isAdmin &&
        (location == Routes.admin || location.startsWith('${Routes.admin}/'))) {
      return Routes.home;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription.cancel();
    super.dispose();
  }
}
