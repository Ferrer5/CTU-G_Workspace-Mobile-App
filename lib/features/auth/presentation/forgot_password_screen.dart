import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_providers.dart';
import '../data/auth_failure.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _successMessage =
      'If the details match an eligible account, a reset email will be sent. '
      'Open the link in the email in a browser to choose a new password.';

  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _feedback;

  @override
  void dispose() {
    _schoolIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateSchoolId(String? value) {
    final schoolId = value?.trim() ?? '';
    if (schoolId.isEmpty) {
      return 'School ID is required.';
    }
    if (schoolId.length > 50) {
      return 'School ID must be 50 characters or fewer.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (email.length > 150) {
      return 'Email must be 150 characters or fewer.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String _failureMessage(AuthFailure failure) {
    if (failure is BackendAuthFailure) {
      if (failure.statusCode == 503 && failure.code == 'recovery_disabled') {
        return 'Password recovery is not available yet.';
      }
      if (failure.statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (failure.statusCode == 400) {
        return 'Please check your School ID and email and try again.';
      }
      if (failure.statusCode >= 500) {
        return 'Password recovery is temporarily unavailable. Please try again later.';
      }
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
    return 'Password recovery could not be completed. Please try again.';
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _feedback = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(
            schoolId: _schoolIdController.text.trim(),
            email: _emailController.text.trim(),
          );
      if (mounted) {
        setState(() => _feedback = _successMessage);
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _feedback = _failureMessage(failure));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenBackground(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthScreenHeader(
                    title: 'Forgot Password?',
                    subtitle: 'Request a reset link using your School ID and registered email.',
                  ),
                  const SizedBox(height: 27),
                  AuthTextField(
                    fieldKey: const Key('recoverySchoolId'),
                    label: 'School ID',
                    controller: _schoolIdController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    maxLength: 50,
                    validator: _validateSchoolId,
                  ),
                  const SizedBox(height: 17),
                  AuthTextField(
                    fieldKey: const Key('recoveryEmail'),
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    maxLength: 150,
                    validator: _validateEmail,
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 17),
                    AuthFeedback(message: _feedback!),
                  ],
                  const SizedBox(height: 23),
                  ElevatedButton(
                    key: const Key('forgotPasswordSubmit'),
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
                        : const Text('Send reset link'),
                  ),
                  const SizedBox(height: 13),
                  Center(
                    child: TextButton(
                      key: const Key('recoveryBackToSignIn'),
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/sign-in'),
                      child: const Text(
                        'Back to Sign In',
                        style: TextStyle(color: Color(0xFF9BE2AA)),
                      ),
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
