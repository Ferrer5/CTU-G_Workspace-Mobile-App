import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../data/auth_failure.dart';
import '../domain/registration_verification.dart';
import 'auth_feedback.dart';
import 'auth_screen_background.dart';
import 'auth_screen_header.dart';
import 'auth_text_field.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class RegistrationVerificationScreen extends ConsumerStatefulWidget {
  const RegistrationVerificationScreen({
    super.key,
    required this.role,
    this.resumed = false,
  });

  final String role;
  final bool resumed;

  @override
  ConsumerState<RegistrationVerificationScreen> createState() =>
      _RegistrationVerificationScreenState();
}

class _RegistrationVerificationScreenState
    extends ConsumerState<RegistrationVerificationScreen> {
  final _code = TextEditingController();
  RegistrationVerification? _state;
  String? _feedback;
  Timer? _ticker;
  int _retryWait = 0;
  bool _loading = true;
  bool _busy = false;
  bool _expired = false;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreStatus());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _setWait(int seconds) {
    _ticker?.cancel();
    _retryWait = seconds;
    if (seconds > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() => _retryWait = (_retryWait - 1).clamp(0, 86400));
        if (_retryWait == 0) timer.cancel();
      });
    }
  }

  Future<void> _restoreStatus() async {
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .registrationStatus(role: widget.role);
      if (!mounted) return;
      setState(() {
        _state = result;
        _expired = result.expiresIn == 0;
        _loading = false;
      });
      _setWait(result.retryAfter);
    } on BackendAuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _expired = failure.code == 'expired' || failure.statusCode == 410;
        _feedback = _expired
            ? 'Your saved verification session is unavailable. Start a new registration.'
            : 'We could not confirm your registration status. Check its status again.';
        _loading = false;
      });
    } on AuthFailure {
      if (mounted) {
        setState(() {
          _feedback = 'We could not confirm your registration status. Check its status again.';
          _loading = false;
        });
      }
    }
  }

  String _message(AuthFailure failure) {
    if (failure is BackendAuthFailure) {
      switch (failure.code) {
        case 'otp_invalid':
          return 'The verification code is incorrect. Please try again.';
        case 'otp_expired':
          return 'The code has expired or is unavailable. Request a new code.';
        case 'attempts_exhausted':
          return 'Too many incorrect codes. Cancel this attempt or wait for it to expire before starting again.';
        case 'conflict':
          return 'We could not complete this registration. Please check your information or contact support.';
        case 'expired':
          return 'This registration has expired. Start a new registration.';
        case 'resend_cooldown':
          return 'Please wait before requesting another code.';
        case 'resends_exhausted':
          return 'The resend limit has been reached. Cancel this attempt or wait for it to expire.';
        case 'throttled':
          return 'Too many requests. Please wait before trying again.';
        case 'delivery_failed':
          return 'We could not send the verification email. Your details are saved temporarily; try resending after the waiting period.';
      }
    }
    if (failure is NetworkUnavailableFailure ||
        failure is RequestTimeoutFailure) {
      return 'We could not confirm the result. Check the current status before trying again.';
    }
    return 'We could not confirm the result. Check the current status before trying again.';
  }

  Future<void> _act(String action) async {
    if (_busy || (action == 'resend' && _retryWait > 0)) return;
    if (action == 'verify' && !RegExp(r'^[0-9]{6}$').hasMatch(_code.text)) {
      setState(() => _feedback = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      if (action == 'cancel') {
        await ref
            .read(authRepositoryProvider)
            .cancelRegistration(role: widget.role);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
          );
        }
        return;
      }
      final result = action == 'verify'
          ? await ref
                .read(authRepositoryProvider)
                .verifyRegistrationCode(code: _code.text, role: widget.role)
          : await ref
                .read(authRepositoryProvider)
                .resendRegistrationCode(role: widget.role);
      if (!mounted) return;
      setState(() {
        _state = result;
        _complete = result.isComplete;
        _code.clear();
        if (action == 'resend') {
          _feedback =
              'A new code was sent. The earlier code is no longer valid.';
        }
      });
      _setWait(result.retryAfter);
    } on BackendAuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _feedback = _message(failure);
        if (failure.code == 'expired' || failure.statusCode == 410) {
          _expired = true;
        }
        if (failure.statusCode == 429) {
          _setWait(failure.retryAfterSeconds ?? 60);
        }
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _feedback = _message(failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScreenBackground(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthScreenHeader(
                title: 'Verify your email',
                subtitle: 'Enter the verification code sent to your email.',
                showRequiredNote: false,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_feedback != null) ...[
                const SizedBox(height: 16),
                AuthFeedback(message: _feedback!),
              ],
              if (_complete) ...[
                const SizedBox(height: 20),
                const Text(
                  'Registration submitted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your email is verified. Your account is pending administrative review. You can sign in after approval and activation.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignInScreen(),
                    ),
                  ),
                  child: const Text('Back to Sign In'),
                ),
              ] else if (!_loading && !_expired) ...[
                if (_state != null &&
                        _state!.status == 'existing_verification' ||
                    widget.resumed)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'You already have a registration in progress in this browser, so the details you just submitted were not used. Your original details are unchanged. If your email address was wrong, choose Cancel registration and register again.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'No account has been created yet. Your saved details remain unchanged.',
                  style: TextStyle(color: Colors.white70),
                ),
                if (_state?.deliverySent == true) ...[
                  const SizedBox(height: 16),
                  AuthTextField(
                    fieldKey: const Key('registrationCode'),
                    controller: _code,
                    label: 'Verification code',
                    validator: (_) => null,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_state?.attemptsRemaining ?? 0} attempts remaining.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_state?.attemptsRemaining != 0)
                    ElevatedButton(
                      onPressed: _busy ? null : () => _act('verify'),
                      child: const Text('Verify and submit registration'),
                    ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Your registration is saved temporarily, but we could not send a code. Use Resend code after the waiting period.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                if (_retryWait > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Resend available in $_retryWait seconds',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                if (_state?.resendsRemaining != 0)
                  TextButton(
                    onPressed: _busy || _retryWait > 0
                        ? null
                        : () => _act('resend'),
                    child: const Text('Resend code'),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _act('cancel'),
                  child: const Text('Cancel registration'),
                ),
              ] else if (_expired) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignUpScreen(),
                    ),
                  ),
                  child: const Text('Start new registration'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
