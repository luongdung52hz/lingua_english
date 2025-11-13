import 'package:flutter/material.dart';
import '../../../../resources/styles/colors.dart';

class ValidatedTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(bool)? onValidationChanged;
  final bool initialValid;
  final bool isObscure;
  final VoidCallback? onVisibilityToggle;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool Function(String)? validationLogic; // Cho real-time

  const ValidatedTextFormField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.prefixIcon,
    this.validator,
    this.onValidationChanged,
    this.initialValid = false,
    this.isObscure = false,
    this.onVisibilityToggle,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validationLogic,
  });

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  late bool isValid;
  late Color iconColor;

  @override
  void initState() {
    super.initState();
    isValid = widget.initialValid;
    iconColor = Colors.grey;
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    setState(() {
      iconColor = widget.focusNode.hasFocus ? Colors.blue[200]! : Colors.grey;
    });
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    final newValid = widget.validationLogic?.call(text) ?? text.isNotEmpty;
    if (newValid != isValid) {
      setState(() => isValid = newValid);
      widget.onValidationChanged?.call(newValid);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: widget.keyboardType,
      obscureText: widget.isObscure,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 24, color: iconColor)
            : null,
        suffixIcon: widget.suffixIcon ?? _buildValidationIcon(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isValid ? Colors.green : Colors.grey, width: 1),
        ),
        focusedBorder: AppColors.successBorder,
        errorBorder: AppColors.errorBorder,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: widget.validator,
      onChanged: (_) => _onTextChanged(), // Trigger real-time
    );
  }

  Widget? _buildValidationIcon() {
    final text = widget.controller.text;
    if (text.isEmpty) return null;
    if (isValid) {
      return const Icon(Icons.check, color: Colors.green, size: 24);
    } else {
      return const Icon(Icons.error, color: Colors.red, size: 24);
    }
  }
}