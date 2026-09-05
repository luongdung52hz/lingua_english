import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _googleSignIn = googleSignIn;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final tokens = await googleUser.authentication;
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      ),
    );
  }

  Future<void> signOut() async {
    // Firebase sign-out must still happen if Google has no active session.
    try {
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }
}
