import '../../models/auth_session.dart';
import 'api_client.dart';

/// بيانات الملف الشخصي للزبون من API.
class CustomerProfileData {
  const CustomerProfileData({
    required this.name,
    required this.email,
    required this.phone,
    this.defaultAddress,
  });

  final String name;
  final String email;
  final String phone;
  final String? defaultAddress;

  factory CustomerProfileData.fromJson(Map<String, dynamic> json) {
    return CustomerProfileData(
      name: '${json['name'] ?? ''}'.trim(),
      email: '${json['email'] ?? ''}'.trim(),
      phone: '${json['phone'] ?? ''}'.trim(),
      defaultAddress: '${json['default_address'] ?? ''}'.trim().isEmpty
          ? null
          : '${json['default_address']}'.trim(),
    );
  }

  AuthUser toAuthUser({int? id}) {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      defaultAddress: defaultAddress,
    );
  }
}

/// GET/PATCH /api/customer/profile — حسب api.md
class ProfileApi {
  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/customer/profile
  Future<CustomerProfileData> fetchProfile() async {
    final json = await _client.getFromRoot('/customer/profile');
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('لم يُرجع الخادم بيانات الملف الشخصي');
    }
    return CustomerProfileData.fromJson(data);
  }

  /// PATCH /api/customer/profile
  Future<CustomerProfileData> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? defaultAddress,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
    };
    final address = defaultAddress?.trim();
    if (address != null && address.isNotEmpty) {
      body['default_address'] = address;
    }

    final json = await _client.patchFromRoot('/customer/profile', body: body);
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw FormatException('${json['message'] ?? 'لم يُرجع الخادم بيانات محدّثة'}');
    }
    return CustomerProfileData.fromJson(data);
  }
}
