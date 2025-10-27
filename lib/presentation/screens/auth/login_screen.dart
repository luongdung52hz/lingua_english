import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/route_names.dart';
import '../../../data/datasources/remote/google_signin_service.dart';
import '../../../resources/styles/colors.dart';
import '../../../core/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isPasswordVisible = false;
  bool isEmailValid = false;
  bool isPasswordValid = false;

  final FocusNode emailFocus = FocusNode();
  final FocusNode passFocus = FocusNode();

  Color emailIconColor = const Color(0xffc1d6d3);
  Color passIconColor = const Color(0xffc1d6d3);

  bool emailIsFocus = false;
  bool passIsFocus = false;
  bool loading = false;
  bool loadingGoogle = false;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      if (mounted) context.go(Routes.home);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Đăng nhập thất bại")),
      );
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
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
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
            print('✅ [Google Login] New user created');
          } else {
            await userDocRef.update({
              'name': user?.displayName ?? userDoc.data()?['name'],
              'email': user?.email ?? userDoc.data()?['email'],
              'photoUrl': user?.photoURL ?? userDoc.data()?['photoUrl'],
              'lastLogin': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final progress = userDoc.data()?['completedLessons'] ?? 0;
            print('✅ [Google Login] Existing user, progress preserved: $progress lessons');
          }
        }

        context.go(Routes.home);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập Google bị hủy. Thử lại?')),
          );
        }
      }
    } catch (e) {
      print('❌ [Google Login] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loadingGoogle = false);
    }
  }

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      setState(() {
        emailIsFocus = emailFocus.hasFocus;
        emailIconColor = (emailFocus.hasFocus
            ? Colors.blue[200]
            : Colors.grey)!;
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        isEmailValid =
            emailRegex.hasMatch(emailCtrl.text.trim()) &&
                emailCtrl.text.isNotEmpty;
      });
    });

    passFocus.addListener(() {
      setState(() {
        passIsFocus = passFocus.hasFocus;
        passIconColor = (passFocus.hasFocus ? Colors.blue[200] : Colors.grey)!;
      });
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    emailCtrl.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Image.asset(
                      'lib/resources/assets/images/logo_2.png',
                      height: 124,
                      width: 124,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 20, color: Colors.white);
                      },
                    ),
                  ),

                  const SizedBox(height: 4),

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

                  // Email Field
                  TextFormField(
                    controller: emailCtrl,
                    focusNode: emailFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: "Email của bạn",
                      prefixIcon: Icon(
                        Icons.email,
                        size: 24,
                        color: emailIconColor,
                      ),
                      suffixIcon: isEmailValid
                          ? Icon(Icons.check, color: Colors.green, size: 24)
                          : (emailCtrl.text.isNotEmpty && !isEmailValid)
                          ? Icon(Icons.error, color: Colors.red, size: 24)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isEmailValid ? Colors.blue : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: AppColors.successBorder,
                      errorBorder: AppColors.errorBorder,
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập email";
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(v.trim()))
                        return "Email không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: passCtrl,
                    focusNode: passFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: "Mật khẩu",
                      prefixIcon: Icon(Icons.lock, color: passIconColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: passIconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isPasswordValid ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: AppColors.successBorder,
                      errorBorder: AppColors.errorBorder,
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    obscureText: !isPasswordVisible,
                    validator: (v) =>
                    v!.length < 6 ? "Tối thiểu 6 ký tự" : null,
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

                  const SizedBox(height: 68),
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
                                fontWeight: FontWeight.w900
                            ),
                          ),
                        ),
                      ]
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