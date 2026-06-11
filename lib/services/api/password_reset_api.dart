import '../../config/api_config.dart';
import 'session_api_client.dart';

/// نتيجة التحقق من OTP — يتضمن التوكن المؤقت المُعاد من الخادم.
class PasswordResetVerifyResult {
  const PasswordResetVerifyResult({
    required this.message,
    required this.token,
    required this.email,
  });

  final String message;
  final String token;
  final String email;
}

/// إعادة تعيين كلمة المرور — حسب api.md:
/// POST /api/v1/auth/password/forgot
/// POST /api/v1/auth/password/verify-otp  → يُعيد token + email
/// POST /api/v1/auth/password/reset       → password + token + email (للموبايل)
class PasswordResetApi {
  PasswordResetApi({SessionApiClient? client}) : _client = client ?? SessionApiClient();

  final SessionApiClient _client;

  void dispose() => _client.close();

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<String> sendOtp({required String email}) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/forgot',
      body: {'email': _normalizeEmail(email)},
    );
    return '${json['message'] ?? ''}'.trim();
  }

  Future<PasswordResetVerifyResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/verify-otp',
      body: {
        'email': normalizedEmail,
        'otp': otp.trim(),
      },
    );
    final token = '${json['token'] ?? ''}'.trim();
    if (token.isEmpty) {
      throw FormatException('${json['message'] ?? 'لم يُرجع الخادم توكن إعادة التعيين'}');
    }
    return PasswordResetVerifyResult(
      message: '${json['message'] ?? ''}'.trim(),
      token: token,
      email: '${json['email'] ?? normalizedEmail}'.trim(),
    );
  }

  Future<String> resetPassword({
    required String password,
    required String passwordConfirmation,
    required String resetToken,
    required String email,
  }) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/reset',
      body: {
        'password': password,
        'password_confirmation': passwordConfirmation,
        'token': resetToken,
        'email': _normalizeEmail(email),
      },
    );
    return '${json['message'] ?? ''}'.trim();
  }
}
