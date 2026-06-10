import '../../models/complaint.dart';
import 'api_client.dart';

/// واجهة API الشكاوى للزبون.
/// POST /api/complaints — إضافة شكوى
/// GET /api/complaints/mine — قائمة شكاوى الزبون
class ComplaintsApi {
  ComplaintsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/complaints/mine
  Future<List<Complaint>> fetchMyComplaints() async {
    final json = await _client.getFromRoot('/complaints/mine');
    return _parseList(json);
  }

  /// GET /api/complaints/{id}
  Future<Complaint> fetchComplaint(int id) async {
    final json = await _client.getFromRoot('/complaints/$id');
    final ticket = Complaint.fromApiJson(json);
    if (ticket.apiId == null) {
      throw FormatException('${json['message'] ?? 'تعذر قراءة تفاصيل الشكوى'}');
    }
    return ticket;
  }

  /// POST /api/complaints
  Future<Complaint> createComplaint({
    required int orderId,
    required String category,
    required String subject,
    required String description,
    String priority = 'medium',
  }) async {
    final json = await _client.postFromRoot(
      '/complaints',
      body: {
        'order_id': orderId,
        'category': category,
        'subject': subject,
        'description': description,
        'priority': priority,
      },
    );
    final ticket = Complaint.fromApiJson(json);
    if (ticket.apiId == null) {
      throw FormatException('${json['message'] ?? 'لم يُرجع الخادم الشكوى الجديدة'}');
    }
    return ticket;
  }

  /// POST /api/complaints/{id}/replies
  Future<void> addReply({required int complaintId, required String message}) async {
    await _client.postFromRoot(
      '/complaints/$complaintId/replies',
      body: {'message': message},
    );
  }

  List<Complaint> _parseList(Map<String, dynamic> json) {
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Complaint.fromApiJson)
        .where((c) => c.apiId != null)
        .toList();
  }
}

/// طلب مختصر لقائمة اختيار الطلب في نموذج الشكوى.
class ComplaintOrderOption {
  const ComplaintOrderOption({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;

  factory ComplaintOrderOption.fromApiJson(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id'] ?? ''}') ?? 0;
    final orderNumber = '${json['order_number'] ?? json['id'] ?? ''}'.trim();
    final storeName = '${json['store_name'] ?? ''}'.trim();
    final label = storeName.isEmpty ? '#$orderNumber' : '#$orderNumber · $storeName';
    return ComplaintOrderOption(id: id, label: label);
  }
}

/// جلب طلبات الزبون لربطها بالشكوى.
class OrdersApi {
  OrdersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/orders
  Future<List<ComplaintOrderOption>> fetchOrdersForComplaints() async {
    final json = await _client.getFromRoot('/orders', query: {'per_page': '50'});
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ComplaintOrderOption.fromApiJson)
        .where((o) => o.id > 0)
        .toList();
  }
}
