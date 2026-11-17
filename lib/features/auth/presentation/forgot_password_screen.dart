import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_providers.dart';
import '../data/auth_failure.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';

enum _Stage { email, code, password, done }

enum _Step { request, verify, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _codeSent =
      'If an eligible account uses this email, we sent a 6-digit code.';
  static const _assistedHint =
      'If no email arrives, your account may need assisted recovery. '
      'Contact support.';
  static const _passwordHint =
      'Use at least 8 characters. Avoid common passwords, only numbers, and '
      'details similar to your School ID, Staff ID or email.';
  static const _codeInvalid = 'The code is incorrect or has expired.';
  static const _ticketInvalid =
      'Your verification has expired. Request a new code.';
  static const _passwordField =
      'Choose a stronger password using the requirements shown.';
  static const _mismatch = 'Passwords do not match.';
  static const _done = 'Password changed. You can now sign in.';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Stage _stage = _Stage.email;
  bool _isSubmitting = false;
  bool _showPassword = false;
  int _codeValidSeconds = 600;
  int _resendWait = 0;
  int _retryWait = 0;
  String? _feedback;
  String? _passwordError;
  String? _confirmError;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _blocked => _isSubmitting || _retryWait > 0;

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_resendWait > 0) _resendWait--;
        if (_retryWait > 0) _retryWait--;
      });
      if (_resendWait == 0 && _retryWait == 0) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  void _clearFeedback() {
    _feedback = null;
    _passwordError = null;
    _confirmError = null;
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

  String? _validateCode(String? value) =>
      RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')
      ? null
      : 'Enter the 6-digit code from your email.';

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'New password is required.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (password.length > 128) {
      return 'Password must be 128 characters or fewer.';
    }
    return null;
  }

  String? _validateConfirm(String? value) =>
      value == _passwordController.text ? null : _mismatch;

  void _onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.length > 6 ? digits.substring(0, 6) : digits;
    if (normalized != value) {
      _codeController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
  }

  String _uncertain(_Step step) => switch (step) {
    _Step.request =>
      'We could not confirm that your code was sent. You can send it again.',
    _Step.verify => 'We could not confirm the code check. Enter the code again.',
    _Step.reset =>
      'We could not confirm whether your password was changed. Try signing in '
      'with your new password. If that does not work, start again.',
  };

  void _handleFailure(AuthFailure failure, _Step step) {
    setState(() {
      _clearFeedback();
      if (failure is BackendAuthFailure) {
        if (failure.code == 'recovery_code_invalid') {
          _codeController.clear();
          _feedback = _codeInvalid;
          return;
        }
        if (failure.code == 'reset_session_invalid') {
          _codeController.clear();
          _passwordController.clear();
          _confirmController.clear();
          _stage = _Stage.email;
          _feedback = _ticketInvalid;
          return;
        }
        if (failure.statusCode == 429) {
          _retryWait = failure.retryAfterSeconds ?? 60;
          if (_retryWait > 0) {
            _startTicker();
          }
          return;
        }
        if (failure.statusCode == 403 || failure.code == 'csrf_failed') {
          _feedback = 'The security check expired. Please try again.';
          return;
        }
        if (failure.code == 'recovery_disabled') {
          _feedback = 'Password recovery is not available yet.';
          return;
        }
        if (failure.code == 'recovery_unavailable') {
          _feedback = 'Password recovery is temporarily unavailable. Please try again later.';
          return;
        }
        if (failure.statusCode == 400) {
          final fields = failure.fields ?? const <String, dynamic>{};
          if (step == _Step.reset && fields.containsKey('password')) {
            _passwordError = _passwordField;
          }
          if (step == _Step.reset &&
              fields.containsKey('password_confirmation')) {
            _confirmError = _mismatch;
          }
          if (_passwordError == null && _confirmError == null) {
            _feedback =
                'Password recovery could not be completed. Please try again.';
          }
          return;
        }
      }
      if (failure is NetworkUnavailableFailure) {
        _feedback = 'Can’t reach the server. Check your connection and try again.';
        return;
      }
      _feedback = _uncertain(step);
    });
  }

  Future<void> _run(Future<void> Function() action, _Step step) async {
    if (_blocked) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _clearFeedback();
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) {
        _handleFailure(failure, step);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendCode() => _run(() async {
    final result = await ref
        .read(authRepositoryProvider)
        .requestPasswordResetCode(email: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _codeValidSeconds = result.codeValidSeconds;
      _resendWait = result.resendAfterSeconds;
      _stage = _Stage.code;
      _feedback = _codeSent;
    });
    if (_resendWait > 0) {
      _startTicker();
    }
  }, _Step.request);

  Future<void> _submitEmail() async {
    if (_blocked || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await _sendCode();
  }

  Future<void> _resend() async {
    if (_blocked || _resendWait > 0) {
      return;
    }
    await _sendCode();
  }

  Future<void> _submitCode() async {
    if (_blocked || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final code = _codeController.text;
    await _run(() async {
      try {
        await ref.read(authRepositoryProvider).verifyPasswordResetCode(
          email: _emailController.text.trim(),
          code: code,
        );
        if (mounted) {
          setState(() => _stage = _Stage.password);
        }
      } finally {
        _codeController.clear();
      }
    }, _Step.verify);
  }

  Future<void> _submitPassword() async {
    if (_blocked || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final password = _passwordController.text;
    final confirmation = _confirmController.text;
    await _run(() async {
      try {
        await ref.read(authRepositoryProvider).confirmPasswordReset(
          email: _emailController.text.trim(),
          password: password,
          passwordConfirmation: confirmation,
        );
        if (mounted) {
          setState(() {
            _stage = _Stage.done;
            _feedback = _done;
          });
        }
      } finally {
        _passwordController.clear();
        _confirmController.clear();
      }
    }, _Step.reset);
  }

  void _startOver() {
    setState(() {
      _clearFeedback();
      _codeController.clear();
      _passwordController.clear();
      _confirmController.clear();
      _resendWait = 0;
      _retryWait = 0;
      _stage = _Stage.email;
    });
  }

  String get _codeMinutes {
    final minutes = (_codeValidSeconds / 60).round();
    final shown = minutes < 1 ? 1 : minutes;
    return '$shown minute${shown == 1 ? '' : 's'}';
  }

  String get _subtitle => switch (_stage) {
    _Stage.email =>
      'Enter the email registered to your account. If it matches an eligible '
      'account, we’ll send a 6-digit code.',
    _Stage.code =>
      'The code is valid for $_codeMinutes. '
      'If you don’t see the email, check your spam or junk folder.',
    _Stage.password => 'Choose a new password for your account.',
    _Stage.done => 'Your password has been updated.',
  };

  Widget _primaryButton(String label, String busyLabel, VoidCallback? onTap) {
    return ElevatedButton(
      key: const Key('forgotPasswordSubmit'),
      onPressed: _blocked ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF197747),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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
          : Text(label),
    );
  }

  Widget _visibilityToggle() => IconButton(
    key: const Key('toggleRecoveryPasswordVisibility'),
    tooltip: _showPassword ? 'Hide password' : 'Show password',
    onPressed: () => setState(() => _showPassword = !_showPassword),
    icon: Icon(
      _showPassword ? Icons.visibility_off : Icons.visibility,
      color: Colors.white70,
    ),
  );

  List<Widget> _stageContent() {
    switch (_stage) {
      case _Stage.email:
        return [
          AuthTextField(
            fieldKey: const Key('recoveryEmail'),
            label: 'Registered email',
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
          if (_retryWait > 0) _waitNote(),
          const SizedBox(height: 23),
          _primaryButton('Send code', 'Sending…', _submitEmail),
        ];
      case _Stage.code:
        return [
          AuthTextField(
            fieldKey: const Key('recoveryCode'),
            label: 'Verification code',
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            onChanged: _onCodeChanged,
            validator: _validateCode,
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 17),
            AuthFeedback(message: _feedback!),
          ],
          if (_retryWait > 0) _waitNote(),
          const SizedBox(height: 23),
          _primaryButton('Verify code', 'Checking…', _submitCode),
          const SizedBox(height: 13),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                key: const Key('recoveryResend'),
                onPressed: (_blocked || _resendWait > 0) ? null : _resend,
                child: const Text('Resend code'),
              ),
              OutlinedButton(
                key: const Key('recoveryStartOver'),
                onPressed: _isSubmitting ? null : _startOver,
                child: const Text('Start over'),
              ),
              if (_resendWait > 0)
                Text(
                  'Resend available in ${_resendWait}s',
                  key: const Key('recoveryResendWait'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            _assistedHint,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ];
      case _Stage.password:
        return [
          AuthTextField(
            fieldKey: const Key('recoveryNewPassword'),
            label: 'New password',
            controller: _passwordController,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            maxLength: 128,
            suffixIcon: _visibilityToggle(),
            backendError: _passwordError,
            validator: _validatePassword,
          ),
          const SizedBox(height: 17),
          AuthTextField(
            fieldKey: const Key('recoveryConfirmPassword'),
            label: 'Confirm new password',
            controller: _confirmController,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            maxLength: 128,
            backendError: _confirmError,
            validator: _validateConfirm,
          ),
          const SizedBox(height: 10),
          const Text(
            _passwordHint,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 17),
            AuthFeedback(message: _feedback!),
          ],
          if (_retryWait > 0) _waitNote(),
          const SizedBox(height: 23),
          _primaryButton('Update password', 'Updating…', _submitPassword),
        ];
      case _Stage.done:
        return [
          if (_feedback != null) AuthFeedback(message: _feedback!),
          const SizedBox(height: 23),
          ElevatedButton(
            key: const Key('forgotPasswordSubmit'),
            onPressed: () => context.go('/sign-in'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF197747),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(51),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Back to Sign In'),
          ),
        ];
    }
  }

  Widget _waitNote() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      'Try again in $_retryWait seconds.',
      key: const Key('recoveryRetryWait'),
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );

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
                  AuthScreenHeader(
                    title: 'Forgot Password?',
                    subtitle: _subtitle,
                  ),
                  const SizedBox(height: 27),
                  ..._stageContent(),
                  if (_stage != _Stage.done) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
