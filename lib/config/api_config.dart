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

  static const Duration timeout = Duration(seconds: 30);

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

  /// يبني رابط صورة عبر `GET /api/media/{path}` —
  /// هذا المسار يمر عبر CORS middleware فتعمل الصور على الويب أيضاً،
  /// بعكس `/storage/` المباشر الذي يحجبه المتصفح (بدون Access-Control-Allow-Origin).
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('assets/')) return path;

    var relative = path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // الخادم قد يبني الرابط بـ APP_URL خاطئ (مثل localhost) —
      // نستخرج المسار بعد /storage/ ونعيد بناءه.
      final storageIndex = path.indexOf('/storage/');
      if (storageIndex == -1) return path;
      relative = path.substring(storageIndex + '/storage/'.length);
    }

    relative = relative.startsWith('/') ? relative.substring(1) : relative;
    if (relative.startsWith('storage/')) {
      relative = relative.substring('storage/'.length);
    }
    return '$apiRoot/media/$relative';
  }
}
