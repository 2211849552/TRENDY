import '../../models/saved_address.dart';
import 'api_client.dart';

/// واجهة API عناوين الشحن — حسب api.md:
/// GET /api/addresses — قائمة العناوين
/// POST /api/addresses — إضافة عنوان
class AddressesApi {
  AddressesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/addresses
  Future<List<SavedAddress>> fetchAddresses() async {
    final json = await _client.getFromRoot('/addresses');
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(SavedAddress.fromApiJson)
        .where((a) => a.id.isNotEmpty)
        .toList();
  }

  /// POST /api/addresses
  Future<SavedAddress> createAddress(
    SavedAddress draft, {
    String? fallbackPhone,
  }) async {
    final json = await _client.postFromRoot(
      '/addresses',
      body: draft.toApiBody(fallbackPhone: fallbackPhone),
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return SavedAddress.fromApiJson(data);
    }
    throw FormatException('${json['message'] ?? 'لم يُرجع الخادم العنوان الجديد'}');
  }
}
