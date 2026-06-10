import '../../config/api_config.dart';
import '../../models/auth_session.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// POST /api/v1/auth/customer/login
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/customer/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      withAuth: false,
    );

    final token = _readToken(json);
    if (token == null || token.isEmpty) {
      throw ApiException('لم يُرجع الخادم رمز الدخول');
    }

    var user = _readUser(json);
    await AuthSession.instance.setAuthenticated(token: token, user: user);
    user = await _syncCurrentUser(fallback: user);
    return user;
  }

  /// POST /api/v1/auth/customer/register
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    final json = await _client.post(
      '${ApiConfig.authPrefix}/customer/register',
      body: {
        'name': trimmedName,
        'full_name': trimmedName,
        'email': email.trim(),
        'phone': trimmedPhone,
        'mobile': trimmedPhone,
        'password': password,
        'password_confirmation': password,
      },
      withAuth: false,
    );

    final token = _readToken(json);
    final registeredEmail = '${json['email'] ?? email.trim()}'.trim();
    final message = '${json['message'] ?? ''}'.trim();

    if (token != null && token.isNotEmpty) {
      var user = _readUser(json);
      if (user.name.isEmpty) {
        user = AuthUser(
          id: user.id,
          name: trimmedName,
          email: user.email.isNotEmpty ? user.email : registeredEmail,
          phone: user.phone.isNotEmpty ? user.phone : trimmedPhone,
        );
      }
      await AuthSession.instance.setAuthenticated(token: token, user: user);
      user = await _syncCurrentUser(fallback: user);
      return RegisterResult(
        email: registeredEmail,
        message: message,
        user: user,
        verified: true,
      );
    }

    return RegisterResult(
      email: registeredEmail,
      message: message.isNotEmpty
          ? message
          : 'تم تسجيل الحساب بنجاح. يرجى تفعيل البريد الإلكتروني.',
      verified: false,
    );
  }

  /// POST /api/v1/auth/customer/verify-email
  Future<AuthUser> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/customer/verify-email',
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
      withAuth: false,
    );

    final token = _readToken(json);
    if (token == null || token.isEmpty) {
      throw ApiException('لم يُرجع الخادم رمز الدخول بعد التفعيل');
    }

    var user = _readUser(json);
    await AuthSession.instance.setAuthenticated(token: token, user: user);
    user = await _syncCurrentUser(fallback: user);
    return user;
  }

  /// POST /api/v1/auth/customer/resend-verification
  Future<String> resendVerification({required String email}) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/customer/resend-verification',
      body: {'email': email.trim()},
      withAuth: false,
    );
    return '${json['message'] ?? ''}'.trim();
  }

  /// GET /api/user — جلب بيانات الزبون الكاملة من الخادم.
  Future<AuthUser> fetchCurrentUser() async {
    final json = await _client.getUrl(ApiConfig.currentUserUrl);
    return _readUser(json);
  }

  Future<AuthUser> _syncCurrentUser({required AuthUser fallback}) async {
    try {
      final fresh = await fetchCurrentUser();
      if (fresh.id != null || fresh.name.isNotEmpty || fresh.email.isNotEmpty) {
        await AuthSession.instance.updateUser(fresh);
        return fresh;
      }
    } on ApiException {
      // نُبقي بيانات الاستجابة الأولى إن فشل جلب /api/user.
    }
    return fallback;
  }

  /// POST /api/v1/auth/password/change — تغيير كلمة المرور للمستخدم المسجّل.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final json = await _client.post(
      '${ApiConfig.authPrefix}/password/change',
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
    return '${json['message'] ?? ''}'.trim();
  }

  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    if (AuthSession.instance.isAuthenticated) {
      try {
        await _client.post('${ApiConfig.authPrefix}/logout');
      } on ApiException {
        // نُنهي الجلسة محلياً حتى لو فشل الطلب.
      }
    }
    await AuthSession.instance.clear();
  }

  Future<void> continueAsGuest() => AuthSession.instance.setGuest();

  String? _readToken(Map<String, dynamic> json) {
    final data = json['data'];
    final candidates = [
      json['token'],
      json['access_token'],
      json['plainTextToken'],
      if (data is Map) data['token'],
      if (data is Map) data['access_token'],
      if (data is Map) data['plainTextToken'],
    ];
    for (final value in candidates) {
      final token = value?.toString().trim();
      if (token != null && token.isNotEmpty) return token;
    }
    return null;
  }

  AuthUser _readUser(Map<String, dynamic> json) {
    Map<String, dynamic>? userMap;

    final user = json['user'];
    if (user is Map<String, dynamic>) {
      userMap = user;
    }

    final data = json['data'];
    if (userMap == null && data is Map<String, dynamic>) {
      final nested = data['user'];
      if (nested is Map<String, dynamic>) {
        userMap = nested;
      } else if (data.containsKey('email') || data.containsKey('id')) {
        userMap = data;
      }
    }

    if (userMap == null && (json.containsKey('email') || json.containsKey('id'))) {
      userMap = json;
    }

    if (userMap != null) {
      return AuthUser.fromJson(userMap);
    }

    return const AuthUser(id: null, name: '', email: '', phone: '');
  }
}

class RegisterResult {
  const RegisterResult({
    required this.email,
    required this.message,
    this.user,
    required this.verified,
  });

  final String email;
  final String message;
  final AuthUser? user;
  final bool verified;
}
