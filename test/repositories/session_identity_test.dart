import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_english/data/repositories/user_repository.dart';
import 'package:learn_english/data/repositories/lesson_repository.dart';

class FakeAuth implements FirebaseAuth {
  @override
  User? currentUser;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  FakeUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'repositories resolve current identity after sign-in, sign-out and account switch',
    () {
      final auth = FakeAuth();
      final store = FakeFirestore();
      final users = UserRepository(firestore: store, auth: auth);
      final lessons = LessonRepository(firestore: store, auth: auth);
      expect(users.userId, isEmpty);
      auth.currentUser = FakeUser('A');
      expect(users.userId, 'A');
      expect(lessons.userId, 'A');
      auth.currentUser = null;
      expect(lessons.userId, isEmpty);
      auth.currentUser = FakeUser('B');
      expect(users.userId, 'B');
      expect(lessons.userId, 'B');
    },
  );
}
