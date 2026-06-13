import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'api_env.dart';

/// إعدادات الاتصال بـ API المنصة (Laravel Sanctum).
class ApiConfig {
  ApiConfig._();

  /// عنوان الخادم — أولوية:
  /// 1) `--dart-define=API_BASE_URL=...`
  /// 2) [kApiServerHost] في `api_env.dart`
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    final host = _resolveHost(kApiServerHost);
    return 'http://$host:$kApiServerPort/api/v1';
  }

  static String _resolveHost(String configuredHost) {
    if (configuredHost != 'auto') return configuredHost;
    if (kIsWeb) return '127.0.0.1';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return '127.0.0.1';
  }

  static const Duration timeout = Duration(seconds: 90);

  static const authPrefix = '/auth';

  /// جذر API بدون `/v1` — مثال: `http://domain.com/api`
  static String get apiRoot {
    if (baseUrl.endsWith('/v1')) {
      return baseUrl.substring(0, baseUrl.length - 3);
    }
    return baseUrl;
  }

  /// GET /api/user — يُعيد المستخدم المسجّل حالياً (Sanctum).
  static String get currentUserUrl => '$apiRoot/user';

  /// جذر الخادم بدون `/api` — لروابط الصور والملفات.
  static String get serverOrigin {
    final root = apiRoot;
    if (root.endsWith('/api')) return root.substring(0, root.length - 4);
    return root;
  }

  /// يبني رابط صورة من حقول API (`logo`, `banner_image`) عبر `/storage/...`.
  /// يُعيد بناء الرابط باستخدام [serverOrigin] حتى لو أعاد Laravel `localhost`.
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('assets/')) return trimmed;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _rebuildStorageUrl(trimmed);
    }

    var relative = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (relative.startsWith('storage/')) {
      relative = relative.substring('storage/'.length);
    }
    if (relative.isEmpty) return '';
    return '$serverOrigin/storage/$relative';
  }

  static String _rebuildStorageUrl(String url) {
    final storageIndex = url.indexOf('/storage/');
    if (storageIndex != -1) {
      final relative = url.substring(storageIndex + '/storage/'.length);
      return '$serverOrigin/storage/$relative';
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path;
      final pathStorage = path.indexOf('/storage/');
      if (pathStorage != -1) {
        return '$serverOrigin${path.substring(pathStorage)}';
      }
    }
    return url;
  }
}
