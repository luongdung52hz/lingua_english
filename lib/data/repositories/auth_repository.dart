import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/remote/google_signin_service.dart';
import 'user_repository.dart';

/// Authentication commands and profile persistence; no navigation or widgets.
class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required UserRepository users,
    required GoogleAuthService google,
  }) : _auth = auth,
       _users = users,
       _google = google;
  final FirebaseAuth _auth;
  final UserRepository _users;
  final GoogleAuthService _google;

  Stream<String?> get userIds =>
      _auth.authStateChanges().map((user) => user?.uid);

  Future<void> signIn(
    String input,
    String password, {
    required bool byEmail,
  }) async {
    final email = byEmail ? input.trim() : await _users.emailForUsername(input);
    if (email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _users.ensureProfile();
  }

  Future<bool> signInWithGoogle() async {
    final result = await _google.signInWithGoogle();
    final user = result?.user;
    if (user == null) return false;
    await _users.ensureProfile(
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
    return true;
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _users.ensureProfile(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() => _google.signOut();
}
