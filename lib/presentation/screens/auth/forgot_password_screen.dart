import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/route_names.dart';
import '../../../resources/styles/colors.dart';
import '../../../core/widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  bool isEmailValid = false;

  // FocusNode để theo dõi focus
  final emailFocus = FocusNode();

  // Màu icon
  Color emailIconColor = const Color(0xffc1d6d3);

  // Status Focus
  bool emailIsFocus = false;
  bool loading = false;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await _auth.sendPasswordResetEmail(email: emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liên kết đặt lại mật khẩu đã gửi đến ${emailCtrl.text.trim()}! Kiểm tra email (kể cả thư rác) và click link để reset.'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                context.go(Routes.login);  // Quay về login ngay khi click OK
              },
            ),
          ),
        );
        // Tự động quay về login sau 3 giây nếu không click OK
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go(Routes.login);
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Không thể gửi email';
      switch (e.code) {
        case 'invalid-email':
          errorMsg = 'Email không hợp lệ';
          break;
        case 'user-not-found':
          errorMsg = 'Không tìm thấy tài khoản với email này';
          break;
        default:
          errorMsg = e.message ?? errorMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi không xác định: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Listener cho email
    emailFocus.addListener(() {
      setState(() {
        emailIsFocus = emailFocus.hasFocus;
        emailIconColor = (emailFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        isEmailValid = emailRegex.hasMatch(emailCtrl.text.trim()) && emailCtrl.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    emailFocus.dispose();
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
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    "Quên mật khẩu? ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Nhập email để nhận liên kết đặt lại mật khẩu ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Email Field (giữ nguyên)
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
                          ? const Icon(Icons.check, color: Colors.green, size: 24)
                          : (emailCtrl.text.isNotEmpty && !isEmailValid)
                          ? const Icon(Icons.error, color: Colors.red, size: 24)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isEmailValid ? Colors.green : Colors.grey,
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
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v.trim())) return "Email không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    onPressed: _resetPassword,
                    text: 'Gửi liên kết',
                    isLoading: loading,
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nhớ mật khẩu rồi? ",
                        style: TextStyle(color: AppColors.grey),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}