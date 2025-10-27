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
import '../../../data/models/user_model.dart'; // Import UserModel

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

  // Màu icon
  Color nameIconColor = const Color(0xffc1d6d3);
  Color phoneIconColor = const Color(0xffc1d6d3);
  Color emailIconColor = const Color(0xffc1d6d3);
  Color passIconColor = const Color(0xffc1d6d3);
  Color confirmPassIconColor = const Color(0xffc1d6d3);

  // Status Focus
  bool nameIsFocus = false;
  bool phoneIsFocus = false;
  bool emailIsFocus = false;
  bool passIsFocus = false;
  bool confirmPassIsFocus = false;
  bool loading = false;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();

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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        // Tạo UserModel với dữ liệu form
        final newUser = UserModel(
          uid: user.uid,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          level: 'A1', // Mặc định A1
          progress: 0.0,
          completedLessons: 0,
          totalLessons: 5,
          score: 0,
          dailyCompleted: 0,
          targetDaily: 5, // Số bài/ngày
          dailyStreak: 0,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );

        // Lưu vào Firestore sử dụng toJson()
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          newUser.toJson(),
          SetOptions(merge: true), // An toàn, merge nếu tồn tại
        );

        print('Registered user UID: ${user.uid}'); // Debug ID để kiểm tra liên kết

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công!')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go(Routes.login);
            }
          });
        }
      }
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

    // Listener cho name
    nameFocus.addListener(() {
      setState(() {
        nameIsFocus = nameFocus.hasFocus;
        nameIconColor = (nameFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        isNameValid = nameCtrl.text.trim().isNotEmpty && nameCtrl.text.trim().length >= 2;
      });
    });

    // Listener cho phone
    phoneFocus.addListener(() {
      setState(() {
        phoneIsFocus = phoneFocus.hasFocus;
        phoneIconColor = (phoneFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        final phoneRegex = RegExp(r'^\+?(\d{1,3})?[-. (]*(\d{3,4})?[-. )]*(\d{3,4})?[-. ]*(\d{4,5})$');
        isPhoneValid = phoneRegex.hasMatch(phoneCtrl.text.trim()) && phoneCtrl.text.trim().isNotEmpty;
      });
    });

    // Listener cho email
    emailFocus.addListener(() {
      setState(() {
        emailIsFocus = emailFocus.hasFocus;
        emailIconColor = (emailFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        isEmailValid = emailRegex.hasMatch(emailCtrl.text.trim()) && emailCtrl.text.isNotEmpty;
      });
    });

    // Listener cho password
    passFocus.addListener(() {
      setState(() {
        passIsFocus = passFocus.hasFocus;
        passIconColor = (passFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        isPasswordValid = passCtrl.text.length >= 6;
      });
    });

    // Listener cho confirm password
    confirmPassFocus.addListener(() {
      setState(() {
        confirmPassIsFocus = confirmPassFocus.hasFocus;
        confirmPassIconColor = (confirmPassFocus.hasFocus ? Colors.blue[200]! : Colors.grey);
        isConfirmPasswordValid = confirmPassCtrl.text == passCtrl.text && confirmPassCtrl.text.length >= 6;
      });
    });
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
                    "Tạo tài khoản mới! ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Bắt đầu hành trình học tập của bạn ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  TextFormField(
                    controller: nameCtrl,
                    focusNode: nameFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: "Họ và tên",
                      prefixIcon: Icon(
                        Icons.person,
                        size: 24,
                        color: nameIconColor,
                      ),
                      suffixIcon: isNameValid
                          ? const Icon(Icons.check, color: Colors.green, size: 24)
                          : (nameCtrl.text.isNotEmpty && !isNameValid)
                          ? const Icon(Icons.error, color: Colors.red, size: 24)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isNameValid ? Colors.green : Colors.grey,
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
                      if (v == null || v.isEmpty) return "Nhập họ và tên";
                      if (v.trim().length < 2) return "Họ và tên phải ít nhất 2 ký tự";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    controller: phoneCtrl,
                    focusNode: phoneFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Số điện thoại",
                      prefixIcon: Icon(
                        Icons.phone,
                        size: 24,
                        color: phoneIconColor,
                      ),
                      suffixIcon: isPhoneValid
                          ? const Icon(Icons.check, color: Colors.green, size: 24)
                          : (phoneCtrl.text.isNotEmpty && !isPhoneValid)
                          ? const Icon(Icons.error, color: Colors.red, size: 24)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isPhoneValid ? Colors.green : Colors.grey,
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
                      if (v == null || v.isEmpty) return "Nhập số điện thoại";
                      final phoneRegex = RegExp(r'^\+?(\d{1,3})?[-. (]*(\d{3,4})?[-. )]*(\d{3,4})?[-. ]*(\d{4,5})$');
                      if (!phoneRegex.hasMatch(v.trim())) return "Số điện thoại không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                    validator: (v) => v!.length < 6 ? "Tối thiểu 6 ký tự" : null,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: confirmPassCtrl,
                    focusNode: confirmPassFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: "Nhắc lại mật khẩu",
                      prefixIcon: Icon(Icons.lock_outline, color: confirmPassIconColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: confirmPassIconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isConfirmPasswordValid ? Colors.green : Colors.grey,
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
                    obscureText: !isConfirmPasswordVisible,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nhập lại mật khẩu";
                      if (v.length < 6) return "Tối thiểu 6 ký tự";
                      if (v != passCtrl.text) return "Mật khẩu không khớp";
                      return null;
                    },
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