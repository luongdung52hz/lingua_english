import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:learn_english/presentation/screens/auth/widgets/text_form_field.dart';
import '../../../app/routes/route_names.dart';
import '../../../data/datasources/remote/google_signin_service.dart';
import '../../../resources/styles/colors.dart';
import '../../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailOrUsernameCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool isPasswordVisible = false;
  bool isInputValid = false;
  bool isPasswordValid = false;
  bool isEmailMode = true; // true = Email, false = Username

  final FocusNode emailOrUsernameFocus = FocusNode();
  final FocusNode passFocus = FocusNode();

  bool loading = false;
  bool loadingGoogle = false;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if input is email
  bool _isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input.trim());
  }

  // Get email from username
  Future<String?> _getEmailFromUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting email from username: $e');
      return null;
    }
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      String email = emailOrUsernameCtrl.text.trim();

      // If username mode, get email from username
      if (!isEmailMode) {
        final emailFromUsername = await _getEmailFromUsername(email);
        if (emailFromUsername == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Không tìm thấy tài khoản với tên người dùng này',
          );
        }
        email = emailFromUsername;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: passCtrl.text.trim(),
      );

      if (mounted) {
        // Xóa tất cả GetX controllers
        Get.deleteAll(force: true);

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500),
          ),
        );

        // Đợi một chút để user thấy thông báo
        await Future.delayed(const Duration(milliseconds: 500));

        // Restart toàn bộ app với Phoenix
        Phoenix.rebirth(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Đăng nhập thất bại";

      switch (e.code) {
        case 'user-not-found':
          errorMessage = isEmailMode
              ? 'Không tìm thấy tài khoản với email này'
              : 'Không tìm thấy tài khoản với tên người dùng này';
          break;
        case 'wrong-password':
          errorMessage = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          errorMessage = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          errorMessage = e.message ?? "Đăng nhập thất bại";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => loadingGoogle = true);
    try {
      final googleService = GoogleAuthService();
      final credential = await googleService.signInWithGoogle();

      if (credential != null && mounted) {
        final user = credential.user;
        final uid = user?.uid ?? '';

        if (uid.isNotEmpty) {
          final userDocRef = _firestore.collection('users').doc(uid);
          final userDoc = await userDocRef.get();

          if (!userDoc.exists) {
            await userDocRef.set({
              'uid': uid,
              'name': user?.displayName ?? 'User Google',
              'email': user?.email ?? '',
              'photoUrl': user?.photoURL ?? '',
              'phone': '',
              'level': 'A1',
              'progress': 0.0,
              'completedLessons': 0,
              'totalLessons': 100,
              'dailyCompleted': 0,
              'dailyStreak': 0,
              'score': 0,
              'targetDaily': 5,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print(' [Google Login] New user created');
          } else {
            await userDocRef.update({
              'name': user?.displayName ?? userDoc.data()?['name'],
              'email': user?.email ?? userDoc.data()?['email'],
              'photoUrl': user?.photoURL ?? userDoc.data()?['photoUrl'],
              'lastLogin': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final progress = userDoc.data()?['completedLessons'] ?? 0;
            print(' [Google Login] Existing user, progress preserved: $progress lessons');
          }
        }

        // Xóa tất cả GetX controllers
        Get.deleteAll(force: true);

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập Google thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500),
          ),
        );

        // Đợi một chút
        await Future.delayed(const Duration(milliseconds: 500));

        // Restart toàn bộ app với Phoenix
        Phoenix.rebirth(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập Google bị hủy. Thử lại?')),
          );
        }
      }
    } catch (e) {
      print(' [Google Login] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingGoogle = false);
    }
  }

  void _toggleLoginMode() {
    setState(() {
      isEmailMode = !isEmailMode;
      emailOrUsernameCtrl.clear();
      isInputValid = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailOrUsernameCtrl.dispose();
    passCtrl.dispose();
    emailOrUsernameFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Custom suffix for password visibility
    final passwordSuffixIcon = IconButton(
      icon: Icon(
        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          isPasswordVisible = !isPasswordVisible;
        });
      },
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Image.asset(
                    'lib/resources/assets/images/logo_L_final.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 20, color: Colors.white);
                    },
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Chào mừng trở lại! ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tiếp tục hành trình học tập của bạn ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!isEmailMode) _toggleLoginMode();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isEmailMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 18,
                                    color: isEmailMode ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      color: isEmailMode ? Colors.white : Colors.grey[600],
                                      fontWeight: isEmailMode ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (isEmailMode) _toggleLoginMode();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isEmailMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: !isEmailMode ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Username',
                                    style: TextStyle(
                                      color: !isEmailMode ? Colors.white : Colors.grey[600],
                                      fontWeight: !isEmailMode ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email or Username Field
                  ValidatedTextFormField(
                    controller: emailOrUsernameCtrl,
                    focusNode: emailOrUsernameFocus,
                    key: ValueKey(isEmailMode),
                    hintText: isEmailMode ? "Email của bạn" : "Tên người dùng",
                    prefixIcon: isEmailMode ? Icons.email : Icons.person,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return isEmailMode ? "Nhập email" : "Nhập tên người dùng";
                      }
                      final trimmed = v.trim();
                      if (isEmailMode) {
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(trimmed)) {
                          return "Email không hợp lệ";
                        }
                      } else {
                        if (trimmed.length < 3) {
                          return "Tên người dùng tối thiểu 3 ký tự";
                        }
                      }
                      return null;
                    },
                    onValidationChanged: (valid) => setState(() => isInputValid = valid),
                    validationLogic: (text) {
                      if (text.isEmpty) return false;
                      return isEmailMode ? _isEmail(text) : text.length >= 3;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  ValidatedTextFormField(
                    controller: passCtrl,
                    focusNode: passFocus,
                    hintText: "Mật khẩu",
                    prefixIcon: Icons.lock,
                    validator: (v) => v!.length < 6 ? "Tối thiểu 6 ký tự" : null,
                    onValidationChanged: (valid) => setState(() => isPasswordValid = valid),
                    validationLogic: (text) => text.length >= 6,
                    isObscure: !isPasswordVisible,
                    suffixIcon: passwordSuffixIcon,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(Routes.forgotPassword),
                      child: const Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    onPressed: _loginEmail,
                    text: 'Đăng nhập',
                    isLoading: loading,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "hoặc",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: loadingGoogle ? null : _loginGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: loadingGoogle
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'lib/resources/assets/icons/google.svg',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Đăng nhập với Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Chưa có tài khoản?",
                        style: TextStyle(
                          color: AppColors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.register),
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}