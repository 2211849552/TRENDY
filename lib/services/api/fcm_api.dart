import 'api_client.dart';
import '../../models/push_token_store.dart';

/// POST /api/fcm/token — تفعيل الإشعار الفوري
/// POST /api/fcm/token/unregister — إيقاف الإشعار الفوري
class FcmApi {
  FcmApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<String> registerToken({
    required String deviceToken,
    String? platform,
    String? deviceName,
  }) async {
    final json = await _client.postFromRoot(
      '/fcm/token',
      body: {
        'device_token': deviceToken,
        'platform': platform ?? pushPlatformLabel(),
        if (deviceName != null && deviceName.trim().isNotEmpty)
          'device_name': deviceName.trim(),
      },
    );
    return '${json['message'] ?? ''}'.trim();
  }

  Future<String> unregisterToken({required String deviceToken}) async {
    final json = await _client.postFromRoot(
      '/fcm/token/unregister',
      body: {'device_token': deviceToken},
    );
    return '${json['message'] ?? ''}'.trim();
  }
}
