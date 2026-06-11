import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'api_exception.dart';
import 'session_client_factory.dart'
    if (dart.library.io) 'session_client_factory_io.dart'
    if (dart.library.html) 'session_client_factory_web.dart';
import 'session_http_bundle.dart';

/// عميل HTTP يحافظ على كوكيز الجلسة — مطلوب لمسارات إعادة تعيين كلمة المرور.
class SessionApiClient {
  factory SessionApiClient({http.Client? client}) {
    if (client != null) {
      return SessionApiClient._(SessionHttpBundle(client));
    }
    return SessionApiClient._(createSessionHttpBundle());
  }

  SessionApiClient._(SessionHttpBundle bundle)
      : _bundle = bundle,
        _client = bundle.client;

  final SessionHttpBundle _bundle;
  final http.Client _client;
  final Map<String, String> _cookies = {};

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: {..._headers(), ..._cookieHeaders()},
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      _storeCookies(response);
      return _decodeResponse(response, uri);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_connectionMessage(uri, e.toString()));
    }
  }

  void close() {
    _bundle.close();
    closeNativeSessionHandle(_bundle.nativeHandle);
  }

  Map<String, String> _headers() => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, String> _cookieHeaders() {
    if (_cookies.isEmpty) return const {};
    final value = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return {'Cookie': value};
  }

  void _storeCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    for (final part in raw.split(RegExp(r',(?=[^;]+?=)'))) {
      final first = part.split(';').first.trim();
      final eq = first.indexOf('=');
      if (eq <= 0) continue;
      final name = first.substring(0, eq).trim();
      final value = first.substring(eq + 1).trim();
      if (name.isNotEmpty && value.isNotEmpty) {
        _cookies[name] = value;
      }
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response, Uri uri) {
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
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

  String _connectionMessage(Uri uri, String detail) {
    return 'تعذر الاتصال بـ $uri\n'
        'تأكد أن Laravel يعمل: php artisan serve --host=0.0.0.0 --port=8000';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
