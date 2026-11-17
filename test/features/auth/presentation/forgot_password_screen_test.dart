import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/data/auth_repository.dart';
import 'package:ctug_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedApiClient extends AuthApiClient {
  _UnusedApiClient() : super(dio: Dio(), cookieJar: CookieJar());
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(_UnusedApiClient());

  int requestCalls = 0;
  int verifyCalls = 0;
  int confirmCalls = 0;
  AuthFailure? requestFailure;
  AuthFailure? verifyFailure;
  AuthFailure? confirmFailure;
  Completer<void>? pendingRequest;
  int resendAfterSeconds = 0;
  String? lastEmail;
  String? lastCode;
  ({String password, String confirmation})? lastPasswords;

  @override
  Future<PasswordResetCodeRequest> requestPasswordResetCode({
    required String email,
  }) async {
    requestCalls++;
    lastEmail = email;
    if (requestFailure != null) {
      throw requestFailure!;
    }
    if (pendingRequest != null) {
      await pendingRequest!.future;
    }
    return PasswordResetCodeRequest(
      resendAfterSeconds: resendAfterSeconds,
      codeValidSeconds: 600,
    );
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    verifyCalls++;
    lastEmail = email;
    lastCode = code;
    if (verifyFailure != null) {
      throw verifyFailure!;
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    confirmCalls++;
    lastEmail = email;
    lastPasswords = (
      password: password,
      confirmation: passwordConfirmation,
    );
    if (confirmFailure != null) {
      throw confirmFailure!;
    }
  }
}

Widget _app(_FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: ForgotPasswordScreen()),
  );
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _tapPrimary(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final button = find.byKey(const Key('forgotPasswordSubmit'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _toCodeStage(WidgetTester tester) async {
  await _enter(tester, 'recoveryEmail', 'student@example.edu');
  await _tapPrimary(tester);
}

Future<void> _toPasswordStage(WidgetTester tester) async {
  await _toCodeStage(tester);
  await _enter(tester, 'recoveryCode', '123456');
  await _tapPrimary(tester);
}

void main() {
  testWidgets('email stage validates required and malformed emails', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));

    await tester.tap(find.byKey(const Key('forgotPasswordSubmit')));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.byKey(const Key('recoveryEmail')), findsOneWidget);

    await _enter(tester, 'recoveryEmail', 'not-an-email');
    await _tapPrimary(tester);

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.requestCalls, 0);
  });

  testWidgets('email stage trims the address and moves to the code stage', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));

    await _enter(tester, 'recoveryEmail', ' student@example.edu ');
    await _tapPrimary(tester);

    expect(repository.lastEmail, 'student@example.edu');
    expect(repository.requestCalls, 1);
    expect(
      find.text('If an eligible account uses this email, we sent a 6-digit code.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('recoveryCode')), findsOneWidget);
  });

  testWidgets('code stage validates the six-digit code and normalizes pasted input', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));
    await _toCodeStage(tester);

    await _enter(tester, 'recoveryCode', '12');
    await _tapPrimary(tester);
    expect(find.text('Enter the 6-digit code from your email.'), findsOneWidget);
    expect(repository.verifyCalls, 0);

    await _enter(tester, 'recoveryCode', '123-456 789');
    await tester.pump();

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('recoveryCode')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '123456');
  });

  testWidgets('full recovery flow sends email, validates code, and updates password', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));
    await _toPasswordStage(tester);

    expect(repository.lastCode, '123456');
    expect(repository.verifyCalls, 1);
    expect(find.byKey(const Key('recoveryNewPassword')), findsOneWidget);

    await _enter(tester, 'recoveryNewPassword', 'NewPassw0rd!x');
    await _enter(tester, 'recoveryConfirmPassword', 'NewPassw0rd!x');
    await _tapPrimary(tester);

    expect(repository.confirmCalls, 1);
    expect(repository.lastPasswords, (
      password: 'NewPassw0rd!x',
      confirmation: 'NewPassw0rd!x',
    ));
    expect(find.text('Password changed. You can now sign in.'), findsOneWidget);
    expect(find.byKey(const Key('forgotPasswordSubmit')), findsOneWidget);
  });

  testWidgets('wrong code shows the fixed validation message', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..verifyFailure = const BackendAuthFailure(
        statusCode: 400,
        code: 'recovery_code_invalid',
        message: 'Sensitive backend wording',
      );
    await tester.pumpWidget(_app(repository));
    await _toCodeStage(tester);

    await _enter(tester, 'recoveryCode', '123456');
    await _tapPrimary(tester);

    expect(find.text('The code is incorrect or has expired.'), findsOneWidget);
    expect(find.text('Sensitive backend wording'), findsNothing);
    expect(find.byKey(const Key('recoveryCode')), findsOneWidget);
  });

  testWidgets('expired ticket resets the flow back to the email stage', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..confirmFailure = const BackendAuthFailure(
        statusCode: 400,
        code: 'reset_session_invalid',
        message: 'Sensitive backend wording',
      );
    await tester.pumpWidget(_app(repository));
    await _toPasswordStage(tester);

    await _enter(tester, 'recoveryNewPassword', 'NewPassw0rd!x');
    await _enter(tester, 'recoveryConfirmPassword', 'NewPassw0rd!x');
    await _tapPrimary(tester);

    expect(
      find.text('Your verification has expired. Request a new code.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('recoveryEmail')), findsOneWidget);
    expect(find.byKey(const Key('recoveryNewPassword')), findsNothing);
  });

  testWidgets('password stage blocks weak or mismatched values', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));
    await _toPasswordStage(tester);

    await _enter(tester, 'recoveryNewPassword', 'short');
    await _enter(tester, 'recoveryConfirmPassword', 'different');
    await _tapPrimary(tester);

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(repository.confirmCalls, 0);
  });

  testWidgets('rate-limit responses show the wait countdown and disable the button', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..requestFailure = const BackendAuthFailure(
        statusCode: 429,
        code: 'throttled',
        message: 'Sensitive backend wording',
        retryAfterSeconds: 30,
      );
    await tester.pumpWidget(_app(repository));
    await _enter(tester, 'recoveryEmail', 'student@example.edu');
    await _tapPrimary(tester);

    expect(find.text('Try again in 30 seconds.'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('forgotPasswordSubmit')))
          .onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Try again in 29 seconds.'), findsOneWidget);
  });

  testWidgets('resend wait is shown and released after the countdown', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()..resendAfterSeconds = 2;
    await tester.pumpWidget(_app(repository));
    await _toCodeStage(tester);

    final resend = find.byKey(const Key('recoveryResend'));
    expect(find.text('Resend available in 2s'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(resend).onPressed, isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<OutlinedButton>(resend).onPressed, isNotNull);
  });

  testWidgets('network and timeout failures show safe messages', (
    tester,
  ) async {
    final cases = <(AuthFailure, String)>[
      (
        NetworkUnavailableFailure(),
        'Can’t reach the server. Check your connection and try again.',
      ),
      (
        RequestTimeoutFailure(),
        'We could not confirm that your code was sent. You can send it again.',
      ),
    ];

    for (final (failure, message) in cases) {
      final repository = _FakeAuthRepository()..requestFailure = failure;
      await tester.pumpWidget(_app(repository));
      await _enter(tester, 'recoveryEmail', 'student@example.edu');
      await _tapPrimary(tester);

      expect(find.text(message), findsOneWidget);
      expect(find.text(failure.message), findsNothing);
    }
  });
}
