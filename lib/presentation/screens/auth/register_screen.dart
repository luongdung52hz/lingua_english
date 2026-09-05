import '../../../data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/screens/auth/widgets/text_form_field.dart';
import '../../../app/routes/route_names.dart';
import '../../../resources/styles/colors.dart';
import '../../widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isNameValid = false;
  bool isPhoneValid = false;
  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;

  // FocusNodes để theo dõi focus
  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();
  final confirmPassFocus = FocusNode();

  bool loading = false;
  final AuthRepository _auth = GetIt.I<AuthRepository>();

  Future<void> _registerEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (passCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await _auth.register(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        password: passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Đăng ký thất bại';
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'Email đã được sử dụng';
          break;
        case 'weak-password':
          errorMsg = 'Mật khẩu quá yếu';
          break;
        case 'invalid-email':
          errorMsg = 'Email không hợp lệ';
          break;
        default:
          errorMsg = e.message ?? errorMsg;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi không xác định: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Listeners removed - handled internally by ValidatedTextFormField
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    confirmPassFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Custom suffixes for password visibility
    final passwordSuffixIcon = IconButton(
      icon: Icon(
        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors
            .grey, // Simplified; widget handles focus color internally for prefix
      ),
      onPressed: () {
        setState(() {
          isPasswordVisible = !isPasswordVisible;
        });
      },
    );

    final confirmPasswordSuffixIcon = IconButton(
      icon: Icon(
        isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors
            .grey, // Simplified; widget handles focus color internally for prefix
      ),
      onPressed: () {
        setState(() {
          isConfirmPasswordVisible = !isConfirmPasswordVisible;
        });
      },
    );

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
                  const SizedBox(height: 30),
                  Image.asset(
                    'lib/resources/assets/images/logo_L_final.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 20,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tạo tài khoản mới! ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Bắt đầu hành trình học tập của bạn ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Name Field - Replaced with ValidatedTextFormField
                  ValidatedTextFormField(
                    controller: nameCtrl,
                    focusNode: nameFocus,
                    hintText: "Họ và tên",
                    prefixIcon: Icons.person,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập họ và tên";
                      if (v.trim().length < 2)
                        return "Họ và tên phải ít nhất 2 ký tự";
                      return null;
                    },
                    onValidationChanged: (valid) =>
                        setState(() => isNameValid = valid),
                    validationLogic: (text) =>
                        text.trim().isNotEmpty && text.trim().length >= 2,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field - Replaced with ValidatedTextFormField
                  ValidatedTextFormField(
                    controller: phoneCtrl,
                    focusNode: phoneFocus,
                    hintText: "Số điện thoại",
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập số điện thoại";
                      final phoneRegex = RegExp(
                        r'^\+?(\d{1,3})?[-. (]*(\d{3,4})?[-. )]*(\d{3,4})?[-. ]*(\d{4,5})$',
                      );
                      if (!phoneRegex.hasMatch(v.trim()))
                        return "Số điện thoại không hợp lệ";
                      return null;
                    },
                    onValidationChanged: (valid) =>
                        setState(() => isPhoneValid = valid),
                    validationLogic: (text) {
                      final phoneRegex = RegExp(
                        r'^\+?(\d{1,3})?[-. (]*(\d{3,4})?[-. )]*(\d{3,4})?[-. ]*(\d{4,5})$',
                      );
                      return phoneRegex.hasMatch(text.trim()) &&
                          text.trim().isNotEmpty;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field - Replaced with ValidatedTextFormField
                  ValidatedTextFormField(
                    controller: emailCtrl,
                    focusNode: emailFocus,
                    hintText: "Email của bạn",
                    prefixIcon: Icons.email,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập email";
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(v.trim()))
                        return "Email không hợp lệ";
                      return null;
                    },
                    onValidationChanged: (valid) =>
                        setState(() => isEmailValid = valid),
                    validationLogic: (text) {
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      return emailRegex.hasMatch(text.trim()) &&
                          text.isNotEmpty;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field - Replaced with ValidatedTextFormField
                  ValidatedTextFormField(
                    controller: passCtrl,
                    focusNode: passFocus,
                    hintText: "Mật khẩu",
                    prefixIcon: Icons.lock,
                    validator: (v) =>
                        v!.length < 6 ? "Tối thiểu 6 ký tự" : null,
                    onValidationChanged: (valid) =>
                        setState(() => isPasswordValid = valid),
                    validationLogic: (text) => text.length >= 6,
                    isObscure: !isPasswordVisible,
                    suffixIcon: passwordSuffixIcon,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field - Replaced with ValidatedTextFormField
                  ValidatedTextFormField(
                    controller: confirmPassCtrl,
                    focusNode: confirmPassFocus,
                    hintText: "Nhắc lại mật khẩu",
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập lại mật khẩu";
                      if (v.length < 6) return "Tối thiểu 6 ký tự";
                      if (v != passCtrl.text) return "Mật khẩu không khớp";
                      return null;
                    },
                    onValidationChanged: (valid) =>
                        setState(() => isConfirmPasswordValid = valid),
                    validationLogic: (text) =>
                        text == passCtrl.text && text.length >= 6,
                    isObscure: !isConfirmPasswordVisible,
                    suffixIcon: confirmPasswordSuffixIcon,
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    onPressed: _registerEmail,
                    text: 'Đăng ký',
                    isLoading: loading,
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Đã có tài khoản? ",
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
