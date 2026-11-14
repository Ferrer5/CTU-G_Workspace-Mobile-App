import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_state.dart';
import '../auth_providers.dart';
import '../data/auth_failure.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _showPassword = false;
  String? _feedback;

  @override
  void dispose() {
    _schoolIdController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          .read(authControllerProvider.notifier)
          .login(
            schoolId: _schoolIdController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      final state = ref.read(authControllerProvider);
      setState(() {
        _feedback = state.status == AuthStatus.authenticated
            ? 'Sign-in successful.'
            : _signInFailureMessage(state.failure);
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _signInFailureMessage(AuthFailure? failure) {
    if (failure is BackendAuthFailure) {
      if (failure.statusCode == 401) {
        return 'We could not sign you in with those details. Check your School ID and password.';
      }
      if (failure.statusCode == 429) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (failure.statusCode >= 500) {
        return 'Sign-in is temporarily unavailable. Please try again later.';
      }
      if (failure.statusCode == 403) {
        return 'We could not verify this request. Please try again.';
      }
      return 'Please check your details and try again.';
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
    return 'Sign-in could not be completed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenBackground(
      child: Center(
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
                    title: 'Sign In',
                    subtitle: 'Access your CTU-G Workspace account.',
                  ),
                  const SizedBox(height: 27),
                  AuthTextField(
                    fieldKey: const Key('schoolId'),
                    label: 'School ID',
                    controller: _schoolIdController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'School ID is required.';
                      }
                      if (value.length > 50) {
                        return 'School ID must be 50 characters or fewer.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 17),
                  AuthTextField(
                    fieldKey: const Key('password'),
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required.';
                      }
                      return null;
                    },
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 17),
                    AuthFeedback(message: _feedback!),
                  ],
                  const SizedBox(height: 23),
                  ElevatedButton(
                    key: const Key('signInSubmit'),
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
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'New to the workspace?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          key: const Key('goToSignUp'),
                          onPressed: _isSubmitting
                              ? null
                              : () => context.go('/sign-up'),
                          child: const Text(
                            'Create an account',
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
