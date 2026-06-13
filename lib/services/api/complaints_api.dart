import 'package:http/http.dart' as http;

import '../../models/complaint.dart';
import '../product_line_enricher.dart';
import 'api_client.dart';
import 'customer_api_paths.dart';
import 'orders_api.dart';

/// واجهة API الشكاوى — حسب api.md [6]:
/// POST /api/complaints — إضافة شكوى (تصل للإدارة العليا)
/// GET /api/complaints/{id} — تفاصيل شكوى
/// POST /api/complaints/{id}/replies — إضافة رد
class ComplaintsApi {
  ComplaintsApi({ApiClient? client, ProductLineEnricher? enricher})
      : _client = client ?? ApiClient(),
        _enricher = enricher ?? ProductLineEnricher();

  final ApiClient _client;
  final ProductLineEnricher _enricher;

  /// GET /api/complaints/{id}
  Future<Complaint> fetchComplaint(int id) async {
    final json = await _client.getFromRoot(CustomerApiPaths.complaint(id));
    final ticket = Complaint.fromApiJson(json);
    if (ticket.apiId == null) {
      throw FormatException('${json['message'] ?? 'تعذر قراءة تفاصيل الشكوى'}');
    }
    return _enrichProductImages(ticket, json);
  }

  /// POST /api/complaints — يدعم الحقول: order_id, category, subject, description,
  /// priority, attachments[], proof[] (انظر api.md [6]).
  Future<Complaint> createComplaint({
    required int orderId,
    required String category,
    required String subject,
    required String description,
    String priority = 'medium',
    List<http.MultipartFile> attachments = const [],
    List<http.MultipartFile> proof = const [],
  }) async {
    final trimmedSubject = subject.trim();
    final trimmedDescription = description.trim();
    final fields = <String, String>{
      'order_id': '$orderId',
      'category': category,
      'subject': trimmedSubject,
      'description': trimmedDescription,
      'priority': priority,
    };

    final files = <http.MultipartFile>[...attachments, ...proof];
    final Map<String, dynamic> json;

    if (files.isEmpty) {
      json = await _client.postFromRoot(
        CustomerApiPaths.complaints,
        body: {
          'order_id': orderId,
          'category': category,
          'subject': trimmedSubject,
          'description': trimmedDescription,
          'priority': priority,
        },
      );
    } else {
      json = await _client.postMultipartFromRoot(
        CustomerApiPaths.complaints,
        fields: fields,
        files: files,
      );
    }

    final ticket = Complaint.fromApiJson(json);
    if (ticket.apiId == null) {
      final message = '${json['message'] ?? ''}'.trim();
      throw FormatException(
        message.isNotEmpty ? message : 'لم يُرجع الخادم الشكوى الجديدة',
      );
    }

    if (ticket.evidenceImages.isEmpty && ticket.apiId != null) {
      return fetchComplaint(ticket.apiId!);
    }
    return _enrichProductImages(ticket, json);
  }

  Future<Complaint> _enrichProductImages(
    Complaint ticket,
    Map<String, dynamic> json,
  ) async {
    if (ticket.productImages.isNotEmpty) return ticket;

    final map = Complaint.resolvePayload(json);
    final order = map['order'];
    if (order is! Map<String, dynamic>) return ticket;

    final storeId = int.tryParse('${order['store_id'] ?? ''}');
    final storeName = '${order['store_name'] ?? ''}'.trim();
    final items = order['items'];
    if (items is! List) return ticket;

    for (final item in items) {
      if (item is! Map) continue;
      final productName = '${item['product_name'] ?? ''}'.trim();
      if (productName.isEmpty) continue;

      final imageUrl = await _enricher.resolveImageUrl(
        productName: productName,
        storeId: storeId,
        storeName: storeName.isEmpty ? null : storeName,
      );
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return ticket.copyWith(productImages: [imageUrl]);
      }
    }

    return ticket;
  }

  /// POST /api/complaints/{id}/replies
  Future<void> addReply({required int complaintId, required String message}) async {
    await _client.postFromRoot(
      CustomerApiPaths.complaintReplies(complaintId),
      body: {'message': message},
    );
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

/// جلب طلبات الزبون لربطها بالشكوى — GET /api/orders
class ComplaintOrdersApi {
  ComplaintOrdersApi({OrdersApi? orders}) : _orders = orders ?? OrdersApi();

  final OrdersApi _orders;

  Future<List<ComplaintOrderOption>> fetchOrdersForComplaints() async {
    final rows = await _orders.fetchOrdersRaw(perPage: 50);
    return rows
        .where((row) {
          final status = '${row['status'] ?? ''}'.toLowerCase();
          return status != 'cancelled' && status != 'canceled';
        })
        .map(ComplaintOrderOption.fromApiJson)
        .where((o) => o.id > 0)
        .toList();
  }
}
