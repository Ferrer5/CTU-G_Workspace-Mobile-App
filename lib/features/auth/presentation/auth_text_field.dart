import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.validator,
    this.requiredField = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.obscureText = false,
    this.maxLength,
    this.autofillHints,
    this.suffixIcon,
    this.backendError,
    this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool requiredField;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final String? backendError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            requiredField ? '$label *' : '$label (optional)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          key: fieldKey,
          controller: controller,
          validator: validator,
          forceErrorText: backendError,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          autofillHints: autofillHints,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF81D59B),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromRGBO(0, 0, 0, 0.36),
            counterText: '',
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.white38),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFF81D59B),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFFF8A80)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFFF8A80),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
