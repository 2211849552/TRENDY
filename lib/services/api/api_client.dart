import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../config/api_env.dart';
import '../../models/auth_session.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      final token = AuthSession.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool withAuth = true,
    Map<String, String>? query,
  }) async {
    final uri = _uri(ApiConfig.baseUrl, path, query);
    return _send(() => _client.get(uri, headers: _headers(withAuth: withAuth)), uri);
  }

  /// GET على مسارات `/api/...` (خارج `/api/v1`).
  Future<Map<String, dynamic>> getFromRoot(
    String path, {
    bool withAuth = true,
    Map<String, String>? query,
  }) async {
    final uri = _uri(ApiConfig.apiRoot, path, query);
    return _send(() => _client.get(uri, headers: _headers(withAuth: withAuth)), uri);
  }

  Future<Map<String, dynamic>> patchFromRoot(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = _uri(ApiConfig.apiRoot, path, null);
    return _send(
      () => _client.patch(
        uri,
        headers: _headers(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  Future<Map<String, dynamic>> postFromRoot(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = _uri(ApiConfig.apiRoot, path, null);
    return _send(
      () => _client.post(
        uri,
        headers: _headers(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  /// POST multipart/form-data على مسارات `/api/...` (مثل رفع صور التقييم).
  Future<Map<String, dynamic>> postMultipartFromRoot(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    bool withAuth = true,
  }) async {
    final uri = _uri(ApiConfig.apiRoot, path, null);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (withAuth) {
      final token = AuthSession.instance.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.fields.addAll(fields);
    request.files.addAll(files);

    return _send(() async {
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }, uri);
  }

  Future<Map<String, dynamic>> deleteFromRoot(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = _uri(ApiConfig.apiRoot, path, null);
    return _send(
      () => _client.delete(uri, headers: _headers(withAuth: withAuth)),
      uri,
    );
  }

  Uri _uri(String base, String path, Map<String, String>? query) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }

  Future<Map<String, dynamic>> getUrl(
    String url, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(url);
    return _send(() => _client.get(uri, headers: _headers(withAuth: withAuth)), uri);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => _client.post(
        uri,
        headers: _headers(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => _client.patch(
        uri,
        headers: _headers(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => _client.delete(uri, headers: _headers(withAuth: withAuth)),
      uri,
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    const maxAttempts = 2;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request().timeout(ApiConfig.timeout);
        return _decodeResponse(response);
      } on ApiException {
        rethrow;
      } on SocketException catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        throw ApiException(_connectionMessage(uri, e.message));
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        throw ApiException(_timeoutMessage(uri));
      } on HttpException catch (e) {
        throw ApiException(_connectionMessage(uri, e.message));
      } on FormatException catch (e) {
        throw ApiException('استجابة غير صالحة من الخادم: ${e.message}');
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        throw ApiException(_connectionMessage(uri, '$lastError'));
      }
    }

    throw ApiException(_connectionMessage(uri, '$lastError'));
  }

  String _timeoutMessage(Uri uri) {
    return 'انتهت مهلة الاتصال بـ $uri\n'
        'الخادم بطيء أو غير متاح. تأكد أن Laravel يعمل:\n'
        '  php artisan serve --host=0.0.0.0 --port=$kApiServerPort';
  }

  String _connectionMessage(Uri uri, String detail) {
    final origin = ApiConfig.serverOrigin;
    return 'تعذر الاتصال بـ $uri\n'
        'تأكد أن Laravel يعمل:\n'
        '  php artisan serve --host=0.0.0.0 --port=$kApiServerPort\n'
        'وعدّل العنوان في lib/config/api_env.dart (الحالي: $origin)';
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } on FormatException {
        throw ApiException('استجابة غير JSON من الخادم (${response.statusCode})');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json ?? <String, dynamic>{};
    }

    throw _buildException(response.statusCode, json);
  }

  ApiException _buildException(int statusCode, Map<String, dynamic>? json) {
    final errors = <String, List<String>>{};
    final rawErrors = json?['errors'];
    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        final value = entry.value;
        if (value is List) {
          errors['${entry.key}'] = value.map((e) => '$e').toList();
        } else if (value != null) {
          errors['${entry.key}'] = ['$value'];
        }
      }
    }

    final message = _firstNonEmpty([
      if (errors.isNotEmpty) errors.values.expand((e) => e).firstOrNull,
      json?['message']?.toString(),
      'Request failed ($statusCode)',
    ])!;

    return ApiException(message, statusCode: statusCode, errors: errors.isEmpty ? null : errors);
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
