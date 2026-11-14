import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/data/auth_repository.dart';
import 'package:ctug_mobile/features/auth/domain/authenticated_account.dart';
import 'package:ctug_mobile/features/auth/domain/registration_request.dart';
import 'package:ctug_mobile/features/auth/presentation/sign_in_screen.dart';
import 'package:ctug_mobile/features/auth/presentation/sign_up_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedApiClient extends AuthApiClient {
  _UnusedApiClient() : super(dio: Dio(), cookieJar: CookieJar());
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(_UnusedApiClient());

  static const account = AuthenticatedAccount(
    schoolId: '1234567',
    roles: ['Student'],
    permissions: [],
  );

  int loginCalls = 0;
  int registerCalls = 0;
  AuthFailure? loginFailure;
  AuthFailure? registerFailure;
  Completer<AuthenticatedAccount>? pendingLogin;

  @override
  Future<AuthenticatedAccount> login({
    required String schoolId,
    required String password,
  }) async {
    loginCalls++;
    if (loginFailure case final failure?) {
      throw failure;
    }
    if (pendingLogin case final pending?) {
      return pending.future;
    }
    return account;
  }

  @override
  Future<RegistrationAcknowledgement> register(
    RegistrationRequest request,
  ) async {
    registerCalls++;
    if (registerFailure case final failure?) {
      throw failure;
    }
    return const RegistrationAcknowledgement('Backend acknowledgement.');
  }
}

Widget _app(Widget screen, _FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: screen),
  );
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _fillValidSignUp(WidgetTester tester) async {
  await _enter(tester, 'schoolId', '1234567');
  await _enter(tester, 'email', 'student@example.edu');
  await _enter(tester, 'password', 'valid-password');
  await _enter(tester, 'passwordConfirmation', 'valid-password');
  await _enter(tester, 'firstName', 'Maria');
  await _enter(tester, 'lastName', 'Santos');
}

Future<void> _submitSignUp(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final submit = find.byKey(const Key('signUpSubmit'));
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sign-in brand header is top-aligned with a rounded logo', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SignInScreen(), _FakeAuthRepository()));

    expect(tester.getTopLeft(find.text('CTU-G WORKSPACE')).dy, lessThan(70));
    expect(
      tester
          .widget<ClipRRect>(find.byKey(const Key('authBrandLogo')))
          .borderRadius,
      BorderRadius.circular(12),
    );
  });

  testWidgets('sign-up brand header is top-aligned with a rounded logo', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SignUpScreen(), _FakeAuthRepository()));

    expect(tester.getTopLeft(find.text('CTU-G WORKSPACE')).dy, lessThan(70));
    expect(
      tester
          .widget<ClipRRect>(find.byKey(const Key('authBrandLogo')))
          .borderRadius,
      BorderRadius.circular(12),
    );
  });

  testWidgets(
    'sign-in validates required fields and toggles password visibility',
    (tester) async {
      final repository = _FakeAuthRepository();
      await tester.pumpWidget(_app(const SignInScreen(), repository));

      await tester.tap(find.byKey(const Key('signInSubmit')));
      await tester.pump();

      expect(find.text('School ID is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('password')),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('togglePasswordVisibility')));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('password')),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
      expect(repository.loginCalls, 0);
    },
  );

  testWidgets('sign-in loading prevents duplicate submissions', (tester) async {
    final repository = _FakeAuthRepository()
      ..pendingLogin = Completer<AuthenticatedAccount>();
    await tester.pumpWidget(_app(const SignInScreen(), repository));
    await _enter(tester, 'schoolId', '1234567');
    await _enter(tester, 'password', 'password');

    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.loginCalls, 1);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('signInSubmit')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('signInSubmit')));
    expect(repository.loginCalls, 1);

    repository.pendingLogin!.complete(_FakeAuthRepository.account);
    await tester.pumpAndSettle();
    expect(find.text('Sign-in successful.'), findsNothing);
  });

  final signInFailures = <(AuthFailure, String)>[
    (
      const BackendAuthFailure(
        statusCode: 401,
        code: 'invalid_credentials',
        message: 'Sensitive backend wording',
      ),
      'We could not sign you in with those details. Check your School ID and password.',
    ),
    (
      const BackendAuthFailure(
        statusCode: 429,
        code: 'too_many_attempts',
        message: 'Sensitive backend wording',
      ),
      'Too many attempts. Please wait a moment and try again.',
    ),
    (
      const BackendAuthFailure(
        statusCode: 503,
        code: 'auth_unavailable',
        message: 'Sensitive backend wording',
      ),
      'Sign-in is temporarily unavailable. Please try again later.',
    ),
    (
      NetworkUnavailableFailure(),
      'Can’t reach the server. Check your connection and try again.',
    ),
    (
      MalformedJsonResponseFailure(),
      'The server returned an unexpected response. Please try again.',
    ),
  ];

  for (final (failure, message) in signInFailures) {
    testWidgets('sign-in shows a safe message for ${failure.runtimeType}', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()..loginFailure = failure;
      await tester.pumpWidget(_app(const SignInScreen(), repository));
      await _enter(tester, 'schoolId', '1234567');
      await _enter(tester, 'password', 'password');
      await tester.tap(find.byKey(const Key('signInSubmit')));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(find.text('Sensitive backend wording'), findsNothing);
    });
  }

  testWidgets('sign-in uses generic copy for a pending account response', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginFailure = const BackendAuthFailure(
        statusCode: 401,
        code: 'invalid_credentials',
        message: 'This account is pending approval.',
      );
    await tester.pumpWidget(_app(const SignInScreen(), repository));
    await _enter(tester, 'schoolId', '1234567');
    await _enter(tester, 'password', 'password');
    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We could not sign you in with those details. '
        'Check your School ID and password.',
      ),
      findsOneWidget,
    );
    expect(find.text('This account is pending approval.'), findsNothing);
  });

  testWidgets('sign-up validates serializer fields and matching passwords', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(const SignUpScreen(), repository));
    await tester.ensureVisible(find.byKey(const Key('signUpSubmit')));
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pump();

    expect(find.text('School ID is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('First name is required.'), findsOneWidget);
    expect(find.text('Last name is required.'), findsOneWidget);

    await _enter(tester, 'schoolId', '12A3');
    await _enter(tester, 'email', 'student@example.edu');
    await _enter(tester, 'password', 'valid-password');
    await _enter(tester, 'passwordConfirmation', 'not-the-same');
    await _enter(tester, 'firstName', 'Maria');
    await _enter(tester, 'lastName', 'Santos');
    await _submitSignUp(tester);

    expect(find.text('Enter 1–7 digits.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('sign-up displays backend field errors on matching fields', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..registerFailure = const BackendAuthFailure(
        statusCode: 400,
        code: 'validation_error',
        message: 'Sensitive backend wording',
        fields: {
          'school_id': ['School ID is already in use.'],
          'first_name': ['Enter a valid first name.'],
          'password_confirmation': ['Passwords do not match.'],
        },
      );
    await tester.pumpWidget(_app(const SignUpScreen(), repository));
    await _fillValidSignUp(tester);
    await _submitSignUp(tester);

    expect(find.text('School ID is already in use.'), findsOneWidget);
    expect(find.text('Enter a valid first name.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.text('Sensitive backend wording'), findsNothing);
  });

  testWidgets('sign-up success stays unauthenticated and shows neutral copy', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
    await _fillValidSignUp(tester);
    await _submitSignUp(tester);

    expect(
      find.text('If eligible, your request is pending review.'),
      findsOneWidget,
    );
    expect(repository.registerCalls, 1);
    expect(repository.loginCalls, 0);
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });
}
