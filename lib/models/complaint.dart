import '../config/api_config.dart';
import 'auth_session.dart';

class ComplaintReply {
  ComplaintReply({
    required this.message,
    required this.date,
    required this.isFromUser,
  });

  final String message;
  final DateTime date;
  final bool isFromUser;
}

class Complaint {
  Complaint({
    required this.id,
    required this.typeKey,
    required this.subject,
    required this.details,
    required this.createdAt,
    required this.statusKey,
    this.apiId,
    this.ticketNumber,
    this.relatedOrderId,
    this.priority,
    List<String>? evidenceImages,
    List<String>? productImages,
    List<ComplaintReply>? replies,
  })  : evidenceImages = evidenceImages ?? [],
        productImages = productImages ?? [],
        replies = replies ?? [];

  final String id;
  final int? apiId;
  final String? ticketNumber;
  final String typeKey;
  final String subject;
  final String details;
  final String? relatedOrderId;
  final String? priority;
  final DateTime createdAt;
  String statusKey;
  final List<String> evidenceImages;
  final List<String> productImages;
  final List<ComplaintReply> replies;

  /// صور للعرض: مرفقات/أدلة الشكوى أو صورة منتج الطلب.
  List<String> get displayImages =>
      evidenceImages.isNotEmpty ? evidenceImages : productImages;

  Complaint copyWith({
    List<String>? evidenceImages,
    List<String>? productImages,
    List<ComplaintReply>? replies,
    String? statusKey,
  }) {
    return Complaint(
      id: id,
      apiId: apiId,
      ticketNumber: ticketNumber,
      typeKey: typeKey,
      subject: subject,
      details: details,
      relatedOrderId: relatedOrderId,
      priority: priority,
      createdAt: createdAt,
      statusKey: statusKey ?? this.statusKey,
      evidenceImages: evidenceImages ?? this.evidenceImages,
      productImages: productImages ?? this.productImages,
      replies: replies ?? this.replies,
    );
  }

  static const _categoryToTypeKey = {
    'order_issue': 'complaint_type_order',
    'store_issue': 'complaint_type_store',
    'technical_issue': 'complaint_type_technical',
    'general_inquiry': 'complaint_type_general',
  };

  static const _typeKeyToCategory = {
    'complaint_type_order': 'order_issue',
    'complaint_type_store': 'store_issue',
    'complaint_type_technical': 'technical_issue',
    'complaint_type_general': 'general_inquiry',
  };

  static String categoryForTypeKey(String typeKey) =>
      _typeKeyToCategory[typeKey] ?? 'general_inquiry';

  /// نسخة محلية للاحتفاظ بالشكوى حتى لو فشل جلبها لاحقاً من API.
  Map<String, dynamic> toCacheJson() => {
        'id': apiId,
        if (ticketNumber != null) 'ticket_number': ticketNumber,
        'subject': subject,
        'description': details,
        'category': categoryForTypeKey(typeKey),
        'status': statusKey == 'complaint_status_closed' ? 'closed' : 'open',
        if (priority != null) 'priority': priority,
        if (relatedOrderId != null) 'order_id': relatedOrderId,
        'created_at': createdAt.toIso8601String(),
        if (evidenceImages.isNotEmpty) 'evidence_images': evidenceImages,
        if (productImages.isNotEmpty) 'product_images': productImages,
      };

  factory Complaint.fromApiJson(Map<String, dynamic> json) {
    final map = resolvePayload(json);
    final apiId = int.tryParse('${map['id'] ?? ''}');
    final category = '${map['category'] ?? 'general_inquiry'}';
    final status = '${map['status'] ?? 'open'}';
    final order = map['order'];
    final orderId = order is Map ? order['id'] : map['order_id'];
    var evidence = _parseEvidence(map);
    if (evidence.isEmpty) {
      evidence = _readUrlList(map['evidence_images']);
    }

    return Complaint(
      id: apiId != null ? 'complaint_$apiId' : '',
      apiId: apiId,
      ticketNumber: map['ticket_number']?.toString(),
      typeKey: _categoryToTypeKey[category] ?? 'complaint_type_general',
      subject: '${map['subject'] ?? ''}'.trim(),
      details: '${map['description'] ?? ''}'.trim(),
      relatedOrderId: orderId?.toString(),
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}') ?? DateTime.now(),
      statusKey: _statusToKey(status),
      priority: map['priority']?.toString(),
      evidenceImages: evidence,
      productImages: _readUrlList(map['product_images']),
      replies: _parseReplies(map),
    );
  }

  static Map<String, dynamic> resolvePayload(Map<String, dynamic> json) =>
      _unwrapTicket(json) ?? json;

  static List<String> _readUrlList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => ApiConfig.resolveMediaUrl('$item'))
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic>? _unwrapTicket(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data.containsKey('id')) return data;
      final nested = data['complaint'];
      if (nested is Map<String, dynamic>) return nested;
    }
    final complaint = json['complaint'];
    if (complaint is Map<String, dynamic>) return complaint;
    if (json.containsKey('id')) return json;
    return null;
  }

  static String _statusToKey(String status) {
    switch (status) {
      case 'closed':
      case 'resolved':
        return 'complaint_status_closed';
      default:
        return 'complaint_status_open';
    }
  }

  static List<String> _parseEvidence(Map<String, dynamic> map) {
    final urls = <String>[];

    final proofs = map['proofs'];
    if (proofs is List) {
      for (final proof in proofs) {
        if (proof is! Map) continue;
        final url = _resolveImageUrl(
          proof['image_url']?.toString(),
          proof['image_path']?.toString(),
        );
        if (url.isNotEmpty) urls.add(url);
      }
    }

    final attachments = map['attachments'];
    if (attachments is List) {
      for (final attachment in attachments) {
        if (attachment is! Map) continue;
        final url = _resolveAttachmentUrl(Map<String, dynamic>.from(attachment));
        if (url.isNotEmpty) urls.add(url);
      }
    }

    return urls;
  }

  /// Spatie Media: المسار الصحيح `storage/{id}/{file_name}` — وليس `storage/{file_name}` فقط.
  static String _resolveAttachmentUrl(Map<String, dynamic> attachment) {
    final originalUrl = attachment['original_url']?.toString();
    if (originalUrl != null && originalUrl.trim().isNotEmpty) {
      return ApiConfig.resolveMediaUrl(originalUrl);
    }

    final mediaId = int.tryParse('${attachment['id'] ?? ''}');
    final fileName = '${attachment['file_name'] ?? ''}'.trim();
    if (mediaId != null && mediaId > 0 && fileName.isNotEmpty) {
      return ApiConfig.resolveMediaUrl('$mediaId/$fileName');
    }

    return _resolveImageUrl(
      attachment['url']?.toString(),
      fileName.isNotEmpty ? fileName : attachment['path']?.toString(),
    );
  }

  static List<String> parseCachedImages(Map<String, dynamic> map) {
    return _readUrlList(map['evidence_images']) + _readUrlList(map['product_images']);
  }

  static String _resolveImageUrl(String? url, String? path) {
    if (url != null && url.trim().isNotEmpty) {
      return ApiConfig.resolveMediaUrl(url);
    }
    if (path != null && path.trim().isNotEmpty) {
      return ApiConfig.resolveMediaUrl(path);
    }
    return '';
  }

  static List<ComplaintReply> _parseReplies(Map<String, dynamic> map) {
    final currentUserId = AuthSession.instance.user?.id;
    final actions = map['actions'];
    if (actions is! List) return const [];

    return actions
        .whereType<Map<String, dynamic>>()
        .where((a) => '${a['action_type'] ?? ''}' == 'reply')
        .map((a) {
          final staff = a['action_by'];
          final authorId = staff is Map ? int.tryParse('${staff['id'] ?? ''}') : null;
          return ComplaintReply(
            message: '${a['comment'] ?? ''}'.trim(),
            date: DateTime.tryParse('${a['created_at'] ?? ''}') ?? DateTime.now(),
            isFromUser: currentUserId != null && authorId == currentUserId,
          );
        })
        .where((r) => r.message.isNotEmpty)
        .toList();
  }
}
