import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleConfig {
  static const String serverClientId = '982053562617-0p65l70qc4l9fqkq22cvh7ejg22gf8fm.apps.googleusercontent.com';
}

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Bước 1: Đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Bước 2: Lấy token
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Bước 3: Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
       // accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Bước 4: Đăng nhập Firebase
      final userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      print(' Google Sign-In failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
