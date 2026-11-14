import 'dart:convert';

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
    'registration sends exactly the serializer field set and accepts 202',
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
        return jsonResponse({
          'message': 'If eligible, your request is pending review.',
        }, statusCode: 202);
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

      expect(result.message, contains('pending review'));
      client.close();
    },
  );

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
