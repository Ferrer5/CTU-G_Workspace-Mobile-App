import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_providers.dart';
import '../data/auth_failure.dart';
import '../domain/registration_request.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  String _requestedRole = 'Student';
  bool _showPassword = false;
  bool _showConfirmation = false;
  bool _isSubmitting = false;
  String? _feedback;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _schoolIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    super.dispose();
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() {
        _fieldErrors = {..._fieldErrors}..remove(field);
      });
    }
  }

  String? _requiredText(
    String? value, {
    required String label,
    required int maxLength,
  }) {
    if (value == null || value.isEmpty) {
      return '$label is required.';
    }
    if (value.length > maxLength) {
      return '$label must be $maxLength characters or fewer.';
    }
    return null;
  }

  String? _validateSchoolId(String? value) {
    if (value == null || value.isEmpty) {
      return 'School ID is required.';
    }
    if (!RegExp(r'^\d{1,7}$').hasMatch(value)) {
      return 'Enter 1–7 digits.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _requiredText(value, label: 'Email', maxLength: 150);
    if (required != null) {
      return required;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final required = _requiredText(value, label: 'Password', maxLength: 128);
    if (required != null) {
      return required;
    }
    if (value!.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    final required = _requiredText(
      value,
      label: 'Confirm password',
      maxLength: 128,
    );
    if (required != null) {
      return required;
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _backendFieldError(String field) => _fieldErrors[field];

  String _failureMessage(AuthFailure failure) {
    if (failure is BackendAuthFailure && failure.statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (failure is BackendAuthFailure && failure.statusCode >= 500) {
      return 'Registration is temporarily unavailable. Please try again later.';
    }
    if (failure is NetworkUnavailableFailure ||
        failure is RequestTimeoutFailure) {
      return 'Can’t reach the server. Check your connection and try again.';
    }
    if (failure is NonJsonResponseFailure ||
        failure is MalformedJsonResponseFailure ||
        failure is InvalidApiResponseFailure) {
      return 'The server returned an unexpected response. Please try again.';
    }
    if (failure is BackendAuthFailure) {
      return 'Please check the highlighted fields and try again.';
    }
    return 'Registration could not be completed. Please try again.';
  }

  Map<String, String> _extractFieldErrors(AuthFailure failure) {
    if (failure is! BackendAuthFailure || failure.fields == null) {
      return const {};
    }
    final errors = <String, String>{};
    for (final entry in failure.fields!.entries) {
      final value = entry.value;
      if (value is String) {
        errors[entry.key] = value;
      } else if (value is List && value.isNotEmpty && value.first is String) {
        errors[entry.key] = value.first as String;
      }
    }
    return errors;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _feedback = null;
      _fieldErrors = const {};
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            RegistrationRequest(
              schoolId: _schoolIdController.text,
              email: _emailController.text,
              firstName: _firstNameController.text,
              middleName: _middleNameController.text,
              lastName: _lastNameController.text,
              suffix: _suffixController.text,
              requestedRole: _requestedRole,
              password: _passwordController.text,
              passwordConfirmation: _confirmationController.text,
            ),
          );
      if (mounted) {
        setState(() {
          _feedback = 'If eligible, your request is pending review.';
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _feedback = _failureMessage(failure);
          _fieldErrors = _extractFieldErrors(failure);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthScreenHeader(
                    title: 'Create Account',
                    subtitle: 'Student and Instructor registrations require administrative approval.',
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 7),
                        child: Text(
                          'Register as *',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        key: const Key('requestedRole'),
                        initialValue: _requestedRole,
                        dropdownColor: const Color(0xFF1E3029),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(0, 0, 0, 0.36),
                          errorText: _backendFieldError('requested_role'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
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
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'Instructor',
                            child: Text('Instructor'),
                          ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _requestedRole = value);
                                  _clearFieldError('requested_role');
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionHeading('01 — Login Credentials'),
                  AuthTextField(
                    fieldKey: const Key('schoolId'),
                    label: 'School ID',
                    controller: _schoolIdController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 7,
                    backendError: _backendFieldError('school_id'),
                    onChanged: (_) => _clearFieldError('school_id'),
                    validator: _validateSchoolId,
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('email'),
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    autofillHints: const [AutofillHints.email],
                    backendError: _backendFieldError('email'),
                    onChanged: (_) => _clearFieldError('email'),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('password'),
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.next,
                    maxLength: 128,
                    autofillHints: const [AutofillHints.newPassword],
                    backendError: _backendFieldError('password'),
                    onChanged: (_) => _clearFieldError('password'),
                    suffixIcon: IconButton(
                      key: const Key('togglePasswordVisibility'),
                      tooltip: _showPassword
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('passwordConfirmation'),
                    label: 'Confirm password',
                    controller: _confirmationController,
                    obscureText: !_showConfirmation,
                    textInputAction: TextInputAction.next,
                    maxLength: 128,
                    autofillHints: const [AutofillHints.newPassword],
                    backendError: _backendFieldError('password_confirmation'),
                    onChanged: (_) => _clearFieldError('password_confirmation'),
                    suffixIcon: IconButton(
                      key: const Key('toggleConfirmationVisibility'),
                      tooltip: _showConfirmation
                          ? 'Hide confirmation'
                          : 'Show confirmation',
                      onPressed: () {
                        setState(() => _showConfirmation = !_showConfirmation);
                      },
                      icon: Icon(
                        _showConfirmation
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                    ),
                    validator: _validateConfirmation,
                  ),
                  const SizedBox(height: 25),
                  _sectionHeading('02 — Personal Information'),
                  AuthTextField(
                    fieldKey: const Key('firstName'),
                    label: 'First name',
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    backendError: _backendFieldError('first_name'),
                    onChanged: (_) => _clearFieldError('first_name'),
                    validator: (value) => _requiredText(
                      value,
                      label: 'First name',
                      maxLength: 100,
                    ),
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('middleName'),
                    label: 'Middle name',
                    requiredField: false,
                    controller: _middleNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    backendError: _backendFieldError('middle_name'),
                    onChanged: (_) => _clearFieldError('middle_name'),
                    validator: (value) => value != null && value.length > 100
                        ? 'Middle name must be 100 characters or fewer.'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('lastName'),
                    label: 'Last name',
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    backendError: _backendFieldError('last_name'),
                    onChanged: (_) => _clearFieldError('last_name'),
                    validator: (value) => _requiredText(
                      value,
                      label: 'Last name',
                      maxLength: 100,
                    ),
                  ),
                  const SizedBox(height: 15),
                  AuthTextField(
                    fieldKey: const Key('suffix'),
                    label: 'Suffix',
                    requiredField: false,
                    controller: _suffixController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: 20,
                    backendError: _backendFieldError('suffix'),
                    onChanged: (_) => _clearFieldError('suffix'),
                    validator: (value) => value != null && value.length > 20
                        ? 'Suffix must be 20 characters or fewer.'
                        : null,
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 17),
                    AuthFeedback(message: _feedback!),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    key: const Key('signUpSubmit'),
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF197747),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(51),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 13),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already registered?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          key: const Key('goToSignIn'),
                          onPressed: _isSubmitting
                              ? null
                              : () => context.go('/sign-in'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: Color(0xFF9BE2AA)),
                          ),
                        ),
                      ],
                    ),
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
