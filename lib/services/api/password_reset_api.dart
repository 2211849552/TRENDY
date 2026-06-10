import '../../config/api_config.dart';
import 'session_api_client.dart';

class PasswordResetApi {
  PasswordResetApi({SessionApiClient? client}) : _client = client ?? SessionApiClient();

  final SessionApiClient _client;
  String? _resetToken;
  String? _resetEmail;

  void dispose() => _client.close();

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  /// POST /api/v1/auth/password/forgot
  Future<String> sendOtp({required String email}) async {
    _resetToken = null;
    _resetEmail = null;

    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/forgot',
      body: {'email': _normalizeEmail(email)},
    );
    return '${json['message'] ?? ''}'.trim();
  }

  /// POST /api/v1/auth/password/verify-otp
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/verify-otp',
      body: {
        'email': _normalizeEmail(email),
        'otp': otp.trim(),
      },
    );

    final token = '${json['token'] ?? ''}'.trim();
    if (token.isNotEmpty) {
      _resetToken = token;
      _resetEmail = '${json['email'] ?? email}'.trim();
    }

    return '${json['message'] ?? ''}'.trim();
  }

  /// POST /api/v1/auth/password/reset
  Future<String> resetPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final body = <String, dynamic>{
      'password': password,
      'password_confirmation': passwordConfirmation,
    };

    if (_resetToken != null &&
        _resetToken!.isNotEmpty &&
        _resetEmail != null &&
        _resetEmail!.isNotEmpty) {
      body['token'] = _resetToken;
      body['email'] = _resetEmail;
    }

    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/reset',
      body: body,
    );

    _resetToken = null;
    _resetEmail = null;

    return '${json['message'] ?? ''}'.trim();
  }
}
