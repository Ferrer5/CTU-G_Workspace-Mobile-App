import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:ctug_mobile/features/auth/data/auth_api_client.dart';
import 'package:ctug_mobile/features/auth/data/auth_failure.dart';
import 'package:ctug_mobile/features/auth/data/auth_repository.dart';
import 'package:ctug_mobile/features/auth/domain/registration_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth_test_support.dart';

void main() {
  test('uses the CSRF cookie set by the latest bootstrap response', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      final path = request.options.uri.path;
      if (path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked-csrf-token'},
          headers: {
            'set-cookie': ['csrftoken=real-csrf-token; Path=/'],
          },
        );
      }
      if (path.endsWith('/login/')) {
        expect(request.options.headers['X-CSRFToken'], 'real-csrf-token');
        return jsonResponse({
          'authenticated': true,
          'account': {
            'school_id': '1234567',
            'roles': ['Student'],
          },
          'permissions': [],
        });
      }
      fail('Unexpected endpoint');
    });
    final transport = createMockTransport(adapter);
    final uri = Uri.parse('https://auth.example.test/api/v1/');
    await transport.jar.saveFromResponse(uri, [
      Cookie('ctug_review_sandbox_csrf', 'stale-sandbox-csrf')..path = '/',
    ]);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    await client.login(schoolId: '1234567', password: 'secret');

    client.close();
  });

  test(
    'uses JSON, bootstraps CSRF once, and reads the rotated cookie per POST',
    () async {
      final adapter = ScriptedHttpAdapter((request) async {
        final path = request.options.uri.path;
        if (path.endsWith('/csrf/')) {
          return jsonResponse(
            {'csrfToken': 'masked-csrf-token'},
            headers: {
              'set-cookie': [
                'ctug_review_sandbox_csrf=csrf-before-login; Path=/',
              ],
            },
          );
        }
        if (path.endsWith('/login/')) {
          expect(request.options.method, 'POST');
          expect(request.options.headers['X-CSRFToken'], 'csrf-before-login');
          expect(
            request.options.headers[Headers.acceptHeader],
            'application/json',
          );
          expect(
            request.options.headers['content-type'],
            Headers.jsonContentType,
          );
          expect(jsonDecode(request.body!), {
            'school_id': '1234567',
            'password': 'secret',
          });
          return jsonResponse(
            {
              'authenticated': true,
              'account': {
                'school_id': '1234567',
                'roles': ['Student'],
              },
              'permissions': ['workspace.view'],
            },
            headers: {
              'set-cookie': [
                'ctug_review_sandbox_csrf=csrf-after-login; Path=/',
                'ctug_review_sandbox_session=session-secret; Path=/',
              ],
            },
          );
        }
        if (path.endsWith('/logout/')) {
          expect(request.options.headers['X-CSRFToken'], 'csrf-after-login');
          expect(request.options.headers['cookie'], contains('session-secret'));
          expect(jsonDecode(request.body!), isEmpty);
          return jsonResponse({'authenticated': false});
        }
        fail('Unexpected endpoint');
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );

      final account = await client.login(
        schoolId: '1234567',
        password: 'secret',
      );
      expect(account.schoolId, '1234567');
      expect(account.roles, ['Student']);
      await client.logout();

      expect(adapter.requests.map((request) => request.options.uri.path), [
        '/api/v1/auth/csrf/',
        '/api/v1/auth/login/',
        '/api/v1/auth/logout/',
      ]);
      expect(
        await transport.jar.loadForRequest(adapter.requests.first.options.uri),
        isEmpty,
      );
      client.close();
    },
  );

  test('login after logout bootstraps a fresh CSRF cookie', () async {
    var bootstrapCount = 0;
    var loginCount = 0;
    final adapter = ScriptedHttpAdapter((request) async {
      final path = request.options.uri.path;
      if (path.endsWith('/csrf/')) {
        bootstrapCount++;
        return jsonResponse(
          {'csrfToken': 'masked-$bootstrapCount'},
          headers: {
            'set-cookie': ['csrftoken=csrf-$bootstrapCount; Path=/'],
          },
        );
      }
      if (path.endsWith('/login/')) {
        loginCount++;
        expect(
          request.options.headers['X-CSRFToken'],
          loginCount == 1 ? 'csrf-1' : 'csrf-2',
        );
        return jsonResponse(
          {
            'authenticated': true,
            'account': {
              'school_id': '1234567',
              'roles': ['Student'],
            },
            'permissions': [],
          },
          headers: {
            'set-cookie': [
              'csrftoken=csrf-rotated-$loginCount; Path=/',
              'sessionid=session-$loginCount; Path=/',
            ],
          },
        );
      }
      if (path.endsWith('/logout/')) {
        expect(request.options.headers['X-CSRFToken'], 'csrf-rotated-1');
        return jsonResponse({'authenticated': false});
      }
      fail('Unexpected endpoint');
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    await client.login(schoolId: '1234567', password: 'secret');
    await client.logout();
    await client.login(schoolId: '1234567', password: 'secret');

    expect(bootstrapCount, 2);
    expect(loginCount, 2);
    client.close();
  });

  test(
    'login after unauthenticated session restoration reboots CSRF',
    () async {
      var bootstrapCount = 0;
      var loginCount = 0;
      final adapter = ScriptedHttpAdapter((request) async {
        final path = request.options.uri.path;
        if (path.endsWith('/csrf/')) {
          bootstrapCount++;
          return jsonResponse(
            {'csrfToken': 'masked-$bootstrapCount'},
            headers: {
              'set-cookie': ['csrftoken=csrf-$bootstrapCount; Path=/'],
            },
          );
        }
        if (path.endsWith('/login/')) {
          loginCount++;
          expect(
            request.options.headers['X-CSRFToken'],
            loginCount == 1 ? 'csrf-1' : 'csrf-2',
          );
          return jsonResponse(
            {
              'authenticated': true,
              'account': {
                'school_id': '1234567',
                'roles': ['Student'],
              },
              'permissions': [],
            },
            headers: {
              'set-cookie': [
                'csrftoken=csrf-rotated-$loginCount; Path=/',
                'sessionid=session-$loginCount; Path=/',
              ],
            },
          );
        }
        if (path.endsWith('/session/')) {
          return jsonResponse({'authenticated': false});
        }
        fail('Unexpected endpoint');
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );
      final repository = AuthRepository(client);

      await repository.login(schoolId: '1234567', password: 'secret');
      expect(await repository.restoreSession(), isNull);
      await repository.login(schoolId: '1234567', password: 'secret');

      expect(bootstrapCount, 2);
      expect(loginCount, 2);
      client.close();
    },
  );

  test(
    'registration accepts staged 202 without a message and retains its cookie',
    () async {
      final adapter = ScriptedHttpAdapter((request) async {
        if (request.options.uri.path.endsWith('/csrf/')) {
          return jsonResponse(
            {'csrfToken': 'masked'},
            headers: {
              'set-cookie': ['csrftoken=csrf-value; Path=/'],
            },
          );
        }
        expect(request.options.uri.path, endsWith('/register/'));
        expect(
          (jsonDecode(request.body!) as Map<String, dynamic>).keys.toSet(),
          {
            'school_id',
            'email',
            'first_name',
            'middle_name',
            'last_name',
            'suffix',
            'requested_role',
            'password',
            'password_confirmation',
          },
        );
        return jsonResponse(
          {
            'status': 'verification_required',
            'delivery_sent': true,
            'expires_in': 1800,
            'retry_after': 60,
            'resends_remaining': 3,
            'attempts_remaining': 5,
            'code_valid_seconds': 600,
          },
          statusCode: 202,
          headers: {
            'set-cookie': [
              'ctug_student_registration=registration-token-1234567890123456789012345678901234567890; Path=/api/v1/auth/; HttpOnly',
            ],
          },
        );
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );

      final result = await client.register(
        const RegistrationRequest(
          schoolId: '1234567',
          email: 'user@example.edu',
          firstName: 'First',
          middleName: '',
          lastName: 'Last',
          suffix: '',
          requestedRole: 'Student',
          password: 'password',
          passwordConfirmation: 'password',
        ),
      );

      expect(result.status, 'verification_required');
      expect(result.retryAfter, 60);
      expect(
        (await transport.jar.loadForRequest(
          Uri.parse('https://auth.example.test/api/v1/auth/'),
        )).map((cookie) => cookie.name),
        contains('ctug_student_registration'),
      );
      client.close();
    },
  );

  test(
    'registration verification status restores from the persistent cookie jar',
    () async {
      final storage = MemoryCookieStorage();
      final adapter = ScriptedHttpAdapter((request) async {
        if (request.options.uri.path.endsWith('/csrf/')) {
          return jsonResponse(
            {'csrfToken': 'masked'},
            headers: {
              'set-cookie': ['csrftoken=csrf-value; Path=/'],
            },
          );
        }
        expect(request.options.method, 'GET');
        expect(request.options.uri.path, endsWith('/register/verification/'));
        expect(
          request.options.headers['cookie'],
          contains('ctug_student_registration=registration-token'),
        );
        return jsonResponse({
          'status': 'existing_verification',
          'delivery_sent': true,
          'expires_in': 1200,
          'retry_after': 45,
          'resends_remaining': 2,
          'attempts_remaining': 4,
          'code_valid_seconds': 600,
        });
      });
      final transport = createMockTransport(adapter, storage: storage);
      final firstClient = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );
      final authUri = Uri.parse('https://auth.example.test/api/v1/auth/');
      await transport.jar.saveFromResponse(authUri, [
        Cookie('ctug_student_registration', 'registration-token')
          ..path = '/api/v1/auth/',
      ]);
      final reloadedJar = PersistCookieJar(
        persistSession: true,
        storage: storage,
      );
      final reloadedClient = AuthApiClient(
        dio: transport.dio,
        cookieJar: reloadedJar,
      );
      final result = await reloadedClient.registrationStatus();
      expect(result.status, 'existing_verification');
      expect(result.attemptsRemaining, 4);
      expect(adapter.requests.map((request) => request.options.method), [
        'GET',
      ]);
      firstClient.close();
      reloadedClient.close();
    },
  );

  test('registration OTP actions use their exact bodies and report structured errors', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      final path = request.options.uri.path;
      if (path.endsWith('/register/verify/')) {
        expect(jsonDecode(request.body!), {'code': '123456'});
        return jsonResponse({
          'error': {
            'code': 'otp_invalid',
            'message': 'Sensitive backend wording',
          },
        }, statusCode: 400);
      }
      if (path.endsWith('/register/resend/')) {
        expect(jsonDecode(request.body!), isEmpty);
        return jsonResponse({
          'error': {
            'code': 'resend_cooldown',
            'message': 'Wait',
            'retry_after': 37,
          },
        }, statusCode: 429);
      }
      if (path.endsWith('/register/cancel/')) {
        expect(jsonDecode(request.body!), isEmpty);
        return jsonResponse({'status': 'cancelled'});
      }
      fail('Unexpected endpoint');
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);
    await expectLater(
      client.verifyRegistrationCode(code: '123456'),
      throwsA(
        isA<BackendAuthFailure>().having(
          (failure) => failure.code,
          'code',
          'otp_invalid',
        ),
      ),
    );
    await expectLater(
      client.resendRegistrationCode(),
      throwsA(
        isA<BackendAuthFailure>().having(
          (failure) => failure.retryAfterSeconds,
          'retryAfter',
          37,
        ),
      ),
    );
    await client.cancelRegistration();
    expect(
      adapter.requests
          .map((request) => request.options.method)
          .where((method) => method == 'POST')
          .length,
      3,
    );
    client.close();
  });

  test('requestPasswordResetCode posts only the email and returns the timing payload', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      final path = request.options.uri.path;
      if (path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      expect(path, endsWith('/forgot-password/'));
      expect(request.options.method, 'POST');
      expect(request.options.headers['X-CSRFToken'], 'csrf-value');
      expect(request.options.headers['Origin'], 'https://auth.example.test');
      expect(jsonDecode(request.body!), {'email': 'user@example.edu'});
      return jsonResponse({
        'resend_after': 30,
        'code_valid_seconds': 600,
      }, statusCode: 202);
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    final result = await client.requestPasswordResetCode(
      email: 'user@example.edu',
    );

    expect(result.resendAfterSeconds, 30);
    expect(result.codeValidSeconds, 600);
    expect(adapter.requests.map((request) => request.options.uri.path), [
      '/api/v1/auth/csrf/',
      '/api/v1/auth/forgot-password/',
    ]);
    client.close();
  });

  test('verifyPasswordResetCode posts email and code, and confirmPasswordReset sends the ticket cookie', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      final path = request.options.uri.path;
      if (path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      if (path.endsWith('/forgot-password/verify/')) {
        expect(request.options.method, 'POST');
        expect(jsonDecode(request.body!), {
          'email': 'user@example.edu',
          'code': '123456',
        });
        return jsonResponse(
          {'status': 'verified'},
          statusCode: 200,
          headers: {
            'set-cookie': ['ticket=reset-ticket; Path=/'],
          },
        );
      }
      if (path.endsWith('/reset-password/')) {
        expect(
          request.options.headers['cookie'],
          contains('ticket=reset-ticket'),
        );
        expect(jsonDecode(request.body!), {
          'email': 'user@example.edu',
          'password': 'NewPassw0rd!x',
          'password_confirmation': 'NewPassw0rd!x',
        });
        return jsonResponse({'status': 'reset'}, statusCode: 200);
      }
      fail('Unexpected endpoint');
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    await client.verifyPasswordResetCode(
      email: 'user@example.edu',
      code: '123456',
    );
    await client.confirmPasswordReset(
      email: 'user@example.edu',
      password: 'NewPassw0rd!x',
      passwordConfirmation: 'NewPassw0rd!x',
    );

    expect(adapter.requests.map((request) => request.options.uri.path), [
      '/api/v1/auth/csrf/',
      '/api/v1/auth/forgot-password/verify/',
      '/api/v1/auth/reset-password/',
    ]);
    client.close();
  });

  test('requestPasswordResetCode reads Retry-After on a 429', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      return jsonResponse(
        {
          'error': {'code': 'throttled', 'message': 'Too many requests'},
        },
        statusCode: 429,
        headers: {
          'retry-after': ['30'],
        },
      );
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    await expectLater(
      client.requestPasswordResetCode(email: 'user@example.edu'),
      throwsA(
        isA<BackendAuthFailure>()
            .having((failure) => failure.statusCode, 'statusCode', 429)
            .having((failure) => failure.retryAfterSeconds, 'retryAfter', 30),
      ),
    );
    client.close();
  });

  test(
    'connection test accepts only HTTP 200 JSON with a CSRF token',
    () async {
      final successAdapter = ScriptedHttpAdapter(
        (_) async => jsonResponse({'csrfToken': 'masked-token'}),
      );
      final successTransport = createMockTransport(successAdapter);
      final successClient = AuthApiClient(
        dio: successTransport.dio,
        cookieJar: successTransport.jar,
      );
      await successClient.testConnection();
      successClient.close();

      final htmlAdapter = ScriptedHttpAdapter(
        (_) async => rawResponse('<html>ok</html>', contentType: 'text/html'),
      );
      final htmlTransport = createMockTransport(htmlAdapter);
      final htmlClient = AuthApiClient(
        dio: htmlTransport.dio,
        cookieJar: htmlTransport.jar,
      );
      await expectLater(
        htmlClient.testConnection(),
        throwsA(isA<NonJsonResponseFailure>()),
      );
      htmlClient.close();

      for (final response in [
        jsonResponse({'other': 'value'}),
        jsonResponse({'csrfToken': 'masked'}, statusCode: 404),
      ]) {
        final adapter = ScriptedHttpAdapter((_) async => response);
        final transport = createMockTransport(adapter);
        final client = AuthApiClient(
          dio: transport.dio,
          cookieJar: transport.jar,
        );
        await expectLater(
          client.testConnection(),
          throwsA(isA<InvalidApiResponseFailure>()),
        );
        client.close();
      }
    },
  );

  test('connection test safely maps timeout and refused connections', () async {
    for (final (errorType, failure) in [
      (DioExceptionType.connectionTimeout, isA<RequestTimeoutFailure>()),
      (DioExceptionType.connectionError, isA<NetworkUnavailableFailure>()),
    ]) {
      final adapter = ScriptedHttpAdapter((request) async {
        throw DioException(
          requestOptions: request.options,
          type: errorType,
          error: errorType == DioExceptionType.connectionError
              ? const SocketException('Connection refused')
              : null,
        );
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );
      await expectLater(client.testConnection(), throwsA(failure));
      client.close();
    }
  });

  for (final (status, code) in [
    (400, 'validation_error'),
    (429, 'throttled'),
    (500, 'auth_unavailable'),
    (503, 'recovery_disabled'),
  ]) {
    test('forgot-password maps HTTP $status to a backend failure', () async {
      final adapter = ScriptedHttpAdapter((request) async {
        if (request.options.uri.path.endsWith('/csrf/')) {
          return jsonResponse(
            {'csrfToken': 'masked'},
            headers: {
              'set-cookie': ['csrftoken=csrf-value; Path=/'],
            },
          );
        }
        return jsonResponse({
          'error': {'code': code, 'message': 'Sensitive backend wording'},
        }, statusCode: status);
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );

      await expectLater(
        client.requestPasswordReset(
          schoolId: '1234567',
          email: 'user@example.edu',
        ),
        throwsA(
          isA<BackendAuthFailure>()
              .having((failure) => failure.statusCode, 'status', status)
              .having((failure) => failure.code, 'code', code),
        ),
      );
      client.close();
    });
  }

  test('forgot-password maps network errors and rejects invalid verification responses', () async {
    final networkAdapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      throw DioException(
        requestOptions: request.options,
        type: DioExceptionType.connectionError,
      );
    });
    final networkTransport = createMockTransport(networkAdapter);
    final networkClient = AuthApiClient(
      dio: networkTransport.dio,
      cookieJar: networkTransport.jar,
    );

    await expectLater(
      networkClient.requestPasswordResetCode(email: 'user@example.edu'),
      throwsA(isA<NetworkUnavailableFailure>()),
    );
    networkClient.close();

    final invalidAdapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      return jsonResponse({'status': 'bad'}, statusCode: 200);
    });
    final invalidTransport = createMockTransport(invalidAdapter);
    final invalidClient = AuthApiClient(
      dio: invalidTransport.dio,
      cookieJar: invalidTransport.jar,
    );

    await expectLater(
      invalidClient.verifyPasswordResetCode(
        email: 'user@example.edu',
        code: '123456',
      ),
      throwsA(isA<InvalidApiResponseFailure>()),
    );
    invalidClient.close();
  });

  for (final status in [400, 401, 403, 429, 503]) {
    test('parses backend error envelope for HTTP $status', () async {
      final adapter = ScriptedHttpAdapter((request) async {
        if (request.options.uri.path.endsWith('/csrf/')) {
          return jsonResponse(
            {'csrfToken': 'masked'},
            headers: {
              'set-cookie': ['csrftoken=csrf-value; Path=/'],
            },
          );
        }
        return jsonResponse({
          'error': {
            'code': 'test_error',
            'message': 'Safe backend message',
            'fields': {
              'school_id': ['Invalid value.'],
            },
          },
        }, statusCode: status);
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );

      await expectLater(
        client.login(schoolId: 'bad', password: 'bad'),
        throwsA(
          isA<BackendAuthFailure>()
              .having((error) => error.statusCode, 'status', status)
              .having((error) => error.code, 'code', 'test_error')
              .having(
                (error) => error.message,
                'message',
                'Safe backend message',
              )
              .having((error) => error.fields, 'fields', isNotNull),
        ),
      );
      client.close();
    });
  }

  test('distinguishes non-JSON and malformed JSON responses', () async {
    for (final response in [
      rawResponse('<html>error</html>', contentType: 'text/html'),
      rawResponse('{invalid'),
    ]) {
      final adapter = ScriptedHttpAdapter((_) async => response);
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );
      final expected =
          response.headers[Headers.contentTypeHeader]!.single == 'text/html'
          ? isA<NonJsonResponseFailure>()
          : isA<MalformedJsonResponseFailure>();

      await expectLater(client.currentSession(), throwsA(expected));
      client.close();
    }
  });

  test('maps timeout and unavailable network to distinct failures', () async {
    for (final error in [
      (DioExceptionType.connectionTimeout, isA<RequestTimeoutFailure>()),
      (DioExceptionType.connectionError, isA<NetworkUnavailableFailure>()),
    ]) {
      final adapter = ScriptedHttpAdapter((request) async {
        throw DioException(requestOptions: request.options, type: error.$1);
      });
      final transport = createMockTransport(adapter);
      final client = AuthApiClient(
        dio: transport.dio,
        cookieJar: transport.jar,
      );

      await expectLater(client.currentSession(), throwsA(error.$2));
      client.close();
    }
  });

  test('restores authenticated and unauthenticated sessions only from server responses', () async {
    final unauthenticatedAdapter = ScriptedHttpAdapter(
      (_) async => jsonResponse({'authenticated': false}),
    );
    final unauthenticatedTransport = createMockTransport(
      unauthenticatedAdapter,
    );
    final unauthenticatedClient = AuthApiClient(
      dio: unauthenticatedTransport.dio,
      cookieJar: unauthenticatedTransport.jar,
    );
    final sessionUri = Uri.parse('https://auth.example.test/api/v1/');
    await unauthenticatedTransport.jar.saveFromResponse(sessionUri, [
      Cookie('sessionid', 'stale-session')..path = '/',
    ]);

    expect(
      await AuthRepository(unauthenticatedClient).restoreSession(),
      isNull,
    );
    expect(
      await unauthenticatedTransport.jar.loadForRequest(sessionUri),
      isEmpty,
    );

    final authenticatedAdapter = ScriptedHttpAdapter(
      (_) async => jsonResponse({
        'authenticated': true,
        'account': {
          'school_id': '7654321',
          'roles': ['Instructor'],
        },
        'permissions': [],
      }),
    );
    final authenticatedTransport = createMockTransport(authenticatedAdapter);
    final authenticatedClient = AuthApiClient(
      dio: authenticatedTransport.dio,
      cookieJar: authenticatedTransport.jar,
    );

    final account = await AuthRepository(authenticatedClient).restoreSession();
    expect(account?.schoolId, '7654321');
    expect(account?.roles, ['Instructor']);
    unauthenticatedClient.close();
    authenticatedClient.close();
  });

  test('does not clear cookies when logout cannot reach the server', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      if (request.options.uri.path.endsWith('/login/')) {
        return jsonResponse(
          {
            'authenticated': true,
            'account': {
              'school_id': '1234567',
              'roles': ['Student'],
            },
            'permissions': [],
          },
          headers: {
            'set-cookie': ['sessionid=session-secret; Path=/'],
          },
        );
      }
      throw DioException(
        requestOptions: request.options,
        type: DioExceptionType.connectionError,
      );
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);
    await client.login(schoolId: '1234567', password: 'secret');

    await expectLater(
      client.logout(),
      throwsA(isA<NetworkUnavailableFailure>()),
    );

    final cookies = await transport.jar.loadForRequest(
      Uri.parse('https://auth.example.test/api/v1/'),
    );
    expect(cookies.map((cookie) => cookie.name), contains('sessionid'));
    client.close();
  });

  test('rejects login success without the expected account shape', () async {
    final adapter = ScriptedHttpAdapter((request) async {
      if (request.options.uri.path.endsWith('/csrf/')) {
        return jsonResponse(
          {'csrfToken': 'masked'},
          headers: {
            'set-cookie': ['csrftoken=csrf-value; Path=/'],
          },
        );
      }
      return jsonResponse({
        'authenticated': true,
        'account': {'school_id': '1234567', 'roles': []},
        'permissions': [],
      });
    });
    final transport = createMockTransport(adapter);
    final client = AuthApiClient(dio: transport.dio, cookieJar: transport.jar);

    await expectLater(
      client.login(schoolId: '1234567', password: 'secret'),
      throwsA(isA<InvalidApiResponseFailure>()),
    );
    client.close();
  });

  test('configures JSON and bounded timeouts from the app base URL', () {
    final client = createAuthApiClient(
      baseUrl: Uri.parse('https://auth.example.test/api/v1/'),
      cookieJar: CookieJar(),
    );

    expect(client.dio.options.baseUrl, 'https://auth.example.test/api/v1/');
    expect(
      client.dio.options.headers[Headers.acceptHeader],
      'application/json',
    );
    expect(client.dio.options.contentType, Headers.jsonContentType);
    expect(client.dio.options.connectTimeout, const Duration(seconds: 10));
    expect(client.dio.options.sendTimeout, const Duration(seconds: 15));
    expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
    client.close();
  });
}
