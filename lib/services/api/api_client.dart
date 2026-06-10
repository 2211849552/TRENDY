import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      final response = await request().timeout(ApiConfig.timeout);
      return _decodeResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(_connectionMessage(uri, e.message));
    } on HttpException catch (e) {
      throw ApiException(_connectionMessage(uri, e.message));
    } on FormatException catch (e) {
      throw ApiException('استجابة غير صالحة من الخادم: ${e.message}');
    } catch (e) {
      throw ApiException(_connectionMessage(uri, e.toString()));
    }
  }

  String _connectionMessage(Uri uri, String detail) {
    return 'تعذر الاتصال بـ $uri\n'
        'تأكد أن Laravel يعمل: php artisan serve --host=0.0.0.0 --port=8000\n'
        'وعدّل العنوان في lib/config/api_env.dart';
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
