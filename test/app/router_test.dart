import 'dart:async';

import 'package:ctug_mobile/app/router.dart';
import 'package:ctug_mobile/features/auth/auth_providers.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/domain/authenticated_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_auth_repository.dart';

ProviderContainer _container(TestAuthRepository repository) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

Widget _app(ProviderContainer container, GoRouter router) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('restores authenticated sessions and guards sign-in routes', (
    tester,
  ) async {
    final repository = TestAuthRepository(
      restoreHandler: () async => TestAuthRepository.account,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    expect(repository.restoreCalls, 1);
    expect(find.text('Your Workspace'), findsOneWidget);
    expect(find.text('1234567'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('not.displayed.permission'), findsNothing);
    expect(find.text('More features are coming soon.'), findsOneWidget);

    router.go('/sign-in');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    router.go('/sign-up');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets(
    'keeps startup visible while restoring and allows sign-up after',
    (tester) async {
      final restoration = Completer<AuthenticatedAccount?>();
      final repository = TestAuthRepository(
        restoreHandler: () => restoration.future,
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(_app(container, router));
      await tester.pump();
      expect(find.byKey(const Key('startupLoading')), findsOneWidget);

      router.go('/sign-up');
      await tester.pump();
      expect(find.text('Checking your session'), findsOneWidget);

      restoration.complete(null);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('schoolId')), findsOneWidget);

      router.go('/sign-up');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('requestedRole')), findsOneWidget);
    },
  );

  testWidgets('redirects unauthenticated users away from the landing screen', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
  });

  testWidgets('shows a recoverable restore error and retries successfully', (
    tester,
  ) async {
    var attempt = 0;
    final repository = TestAuthRepository(
      restoreHandler: () async {
        attempt++;
        if (attempt == 1) {
          throw const NetworkUnavailableFailure();
        }
        return TestAuthRepository.account;
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t verify your session'), findsOneWidget);
    expect(find.byKey(const Key('retrySessionRestore')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retrySessionRestore')));
    await tester.pumpAndSettle();

    expect(repository.restoreCalls, 2);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
  });

  testWidgets('returns to sign-in when a restored session becomes invalid', (
    tester,
  ) async {
    var attempt = 0;
    final repository = TestAuthRepository(
      restoreHandler: () async {
        attempt++;
        return attempt == 1 ? TestAuthRepository.account : null;
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    await container.read(authControllerProvider.notifier).restoreSession();
    await tester.pumpAndSettle();

    expect(repository.restoreCalls, 2);
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
  });

  testWidgets('logout success clears sign-in fields and back avoids sign-in', (
    tester,
  ) async {
    final logout = Completer<void>();
    final repository = TestAuthRepository(logoutHandler: () => logout.future);
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('schoolId')), '1234567');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(find.text('Your Workspace'), findsOneWidget);
    expect(find.text('Sign-in successful.'), findsNothing);
    expect(router.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('logoutButton')))
          .onPressed,
      isNull,
    );
    logout.complete();
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
    final schoolIdField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('schoolId')),
        matching: find.byType(TextField),
      ),
    );
    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('password')),
        matching: find.byType(TextField),
      ),
    );
    expect(schoolIdField.controller!.text, isEmpty);
    expect(passwordField.controller!.text, isEmpty);
  });

  testWidgets('logout failure keeps account visible and offers a retry', (
    tester,
  ) async {
    var attempt = 0;
    final repository = TestAuthRepository(
      restoreHandler: () async => TestAuthRepository.account,
      logoutHandler: () async {
        attempt++;
        if (attempt == 1) {
          throw const NetworkUnavailableFailure();
        }
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountSchoolId')), findsOneWidget);
    expect(
      find.text(
        'We couldn’t log you out. You are still signed in. Please try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retryLogout')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retryLogout')));
    await tester.pumpAndSettle();
    expect(repository.logoutCalls, 2);
    expect(find.byKey(const Key('signInSubmit')), findsOneWidget);
  });
}
