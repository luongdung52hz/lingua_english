import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleConfig {
  static final String serverClientId = dotenv.env['AUTH_ID'] ?? '';

  static String get webClientId => dotenv.env['CLIENT_ID'] ?? '';
}

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? GoogleConfig.webClientId : null,
  );

  /// Đăng nhập với Google
  ///  Buộc người dùng chọn lại tài khoản mỗi lần đăng nhập
  Future<UserCredential?> signInWithGoogle() async {
    try {
      //  BƯỚC 0: Đăng xuất Google trước để xóa cache
      // Điều này buộc hiển thị màn hình chọn tài khoản
      await _googleSignIn.signOut();
      print(' Google cache cleared - forcing account selection');

      // Bước 1: Đăng nhập Google (sẽ hiển thị màn hình chọn tài khoản)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Nếu người dùng hủy đăng nhập
      if (googleUser == null) {
        print(' User cancelled Google Sign-In');
        return null;
      }

      // Bước 2: Lấy token
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Bước 3: Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, // Nên giữ accessToken
        idToken: googleAuth.idToken,
      );

      // Bước 4: Đăng nhập Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      print(' Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;

    } catch (e) {
      print(' Google Sign-In failed: $e');
      return null;
    }
  }

  /// Đăng xuất khỏi Google và Firebase
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      print(' Signed out from Google and Firebase');
    } catch (e) {
      print(' Sign out error: $e');
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  User? get currentUser => _auth.currentUser;

  /// Stream theo dõi auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}