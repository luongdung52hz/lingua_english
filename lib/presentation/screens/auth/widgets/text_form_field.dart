import 'package:flutter/material.dart';

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
  final bool Function(String)? validationLogic;

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

  @override
  void initState() {
    super.initState();
    isValid = widget.initialValid;
    widget.controller.addListener(_onTextChanged);
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
            ? Icon(widget.prefixIcon, size: 24)
            : null,
        suffixIcon: widget.suffixIcon ?? _buildValidationIcon(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isValid ? Colors.grey : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isValid ? Colors.grey : Colors.blue,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: widget.validator,
    );
  }

  Widget? _buildValidationIcon() {
    final text = widget.controller.text;
    if (text.isEmpty) return null;
    return Icon(
      isValid ? Icons.check_circle : Icons.error,
      color: isValid ? Colors.grey : Colors.red,
      size: 24,
    );
  }
}