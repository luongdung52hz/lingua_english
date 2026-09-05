import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_english/app/routes/route_names.dart';
import 'package:learn_english/presentation/controllers/auth_controller.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late StreamController<String?> ids;
  late AuthController session;
  late int resets;
  late int roleReads;
  late bool onboardingSaved;
  setUp(() {
    ids = StreamController<String?>.broadcast();
    resets = 0;
    roleReads = 0;
    onboardingSaved = false;
    session = AuthController(
      userIds: ids.stream,
      loadAdmin: (uid) async {
        roleReads++;
        return uid == 'admin';
      },
      resetControllers: () async {
        resets++;
      },
      saveOnboarding: () async {
        onboardingSaved = true;
      },
      hasSeenOnboarding: false,
    );
  });
  tearDown(() async {
    session.dispose();
    await ids.close();
  });

  test(
    'signed-out onboarding is persisted and protected routes are guarded',
    () async {
      expect(session.redirect(Routes.home), Routes.splash);
      ids.add(null);
      await flush();
      expect(session.redirect(Routes.home), Routes.onboarding);
      await session.completeOnboarding();
      expect(onboardingSaved, isTrue);
      expect(session.redirect(Routes.home), Routes.login);
      expect(session.redirect(Routes.register), isNull);
    },
  );

  test(
    'auth switches clear session controllers; route changes do not query roles',
    () async {
      ids.add('admin');
      await flush();
      expect(session.redirect(Routes.login), Routes.admin);
      expect(session.redirect(Routes.home), Routes.admin);
      expect(roleReads, 1);
      ids.add('admin');
      await flush();
      expect(resets, 1);
      ids.add(null);
      await flush();
      ids.add('student');
      await flush();
      expect(resets, 3);
      expect(session.redirect(Routes.admin), Routes.home);
      expect(session.redirect(Routes.learn), isNull);
    },
  );

  test(
    'late admin result cannot grant access to a newer signed-out session',
    () async {
      session.dispose();
      final pending = Completer<bool>();
      session = AuthController(
        userIds: ids.stream,
        loadAdmin: (_) => pending.future,
        resetControllers: () async {},
        saveOnboarding: () async {},
        hasSeenOnboarding: true,
      );
      ids.add('admin');
      await flush();
      ids.add(null);
      await flush();
      pending.complete(true);
      await flush();
      expect(session.userId, isNull);
      expect(session.isAdmin, isFalse);
      expect(session.redirect(Routes.admin), Routes.login);
    },
  );

  test('failed role lookup fails closed', () async {
    session.dispose();
    session = AuthController(
      userIds: ids.stream,
      loadAdmin: (_) async => throw StateError('offline'),
      resetControllers: () async {},
      saveOnboarding: () async {},
      hasSeenOnboarding: true,
    );
    ids.add('student');
    await flush();
    expect(session.isReady, isTrue);
    expect(session.isAdmin, isFalse);
    expect(session.redirect(Routes.admin), Routes.home);
  });
}
