import 'dart:async';
import 'dart:convert';

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

import '../auth_test_support.dart';

class _UnusedApiClient extends AuthApiClient {
  _UnusedApiClient() : super(dio: Dio(), cookieJar: CookieJar());
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(_UnusedApiClient());

  int requestCalls = 0;
  AuthFailure? requestFailure;
  Completer<void>? pendingRequest;
  ({String schoolId, String email})? lastRequest;

  @override
  Future<void> requestPasswordReset({
    required String schoolId,
    required String email,
  }) async {
    requestCalls++;
    lastRequest = (schoolId: schoolId, email: email);
    if (requestFailure != null) {
      throw requestFailure!;
    }
    if (pendingRequest != null) {
      await pendingRequest!.future;
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

Future<void> _fillValidForm(WidgetTester tester) async {
  await _enter(tester, 'recoverySchoolId', '1234567');
  await _enter(tester, 'recoveryEmail', 'student@example.edu');
}

Future<void> _submit(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final submit = find.byKey(const Key('forgotPasswordSubmit'));
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses the auth background and rounded brand header', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeAuthRepository()));

    expect(tester.getTopLeft(find.text('CTU-G WORKSPACE')).dy, lessThan(70));
    expect(
      tester
          .widget<ClipRRect>(find.byKey(const Key('authBrandLogo')))
          .borderRadius,
      BorderRadius.circular(12),
    );
  });

  testWidgets('validates required fields, email format, and maximum lengths', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));
    await tester.tap(find.byKey(const Key('forgotPasswordSubmit')));
    await tester.pump();

    expect(find.text('School ID is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);

    await _enter(tester, 'recoverySchoolId', '1234567');
    await _enter(tester, 'recoveryEmail', 'not-an-email');
    await _submit(tester);

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.requestCalls, 0);

    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('recoverySchoolId')),
              matching: find.byType(TextField),
            ),
          )
          .maxLength,
      50,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('recoveryEmail')),
              matching: find.byType(TextField),
            ),
          )
          .maxLength,
      150,
    );
  });

  testWidgets('shows neutral success copy and submits trimmed contract values', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_app(repository));
    await _enter(tester, 'recoverySchoolId', ' 1234567 ');
    await _enter(tester, 'recoveryEmail', ' student@example.edu ');
    await _submit(tester);

    expect(
      find.text(
        'If the details match an eligible account, a reset email will be sent. '
        'Open the link in the email in a browser to choose a new password.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('account does not exist'), findsNothing);
    expect(repository.requestCalls, 1);
    expect(repository.lastRequest, (
      schoolId: '1234567',
      email: 'student@example.edu',
    ));
  });

  testWidgets('never displays the backend success response text', (
    tester,
  ) async {
    final adapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      expect(jsonDecode(request.body!), {
        'school_id': '1234567',
        'email': 'student@example.edu',
      });
      return jsonResponse({
        'message': 'This account exists and a reset email was sent.',
      }, statusCode: 202);
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);
    addTearDown(client.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(client)),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await _fillValidForm(tester);
    await _submit(tester);

    expect(
      find.text(
        'If the details match an eligible account, a reset email will be sent. '
        'Open the link in the email in a browser to choose a new password.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('This account exists and a reset email was sent.'),
      findsNothing,
    );
  });

  final failures = <(AuthFailure, String)>[
    (
      const BackendAuthFailure(
        statusCode: 503,
        code: 'recovery_disabled',
        message: 'Sensitive backend wording',
      ),
      'Password recovery is not available yet.',
    ),
    (
      const BackendAuthFailure(
        statusCode: 429,
        code: 'throttled',
        message: 'Sensitive backend wording',
      ),
      'Too many requests. Please wait a moment and try again.',
    ),
    (
      const BackendAuthFailure(
        statusCode: 500,
        code: 'auth_unavailable',
        message: 'Sensitive backend wording',
      ),
      'Password recovery is temporarily unavailable. Please try again later.',
    ),
    (
      const BackendAuthFailure(
        statusCode: 400,
        code: 'validation_error',
        message: 'This account does not exist.',
      ),
      'Please check your School ID and email and try again.',
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

  for (final (failure, message) in failures) {
    testWidgets('shows a safe message for ${failure.runtimeType}', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()..requestFailure = failure;
      await tester.pumpWidget(_app(repository));
      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(message), findsOneWidget);
      expect(find.text(failure.message), findsNothing);
    });
  }

  testWidgets('loading state prevents duplicate recovery requests', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..pendingRequest = Completer<void>();
    await tester.pumpWidget(_app(repository));
    await _fillValidForm(tester);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('forgotPasswordSubmit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.requestCalls, 1);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await tester.tap(submit);
    expect(repository.requestCalls, 1);

    repository.pendingRequest!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('reset email will be sent'), findsOneWidget);
  });
}
