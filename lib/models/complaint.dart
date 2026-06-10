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
    List<String>? evidenceImages,
    List<ComplaintReply>? replies,
  })  : evidenceImages = evidenceImages ?? [],
        replies = replies ?? [];

  final String id;
  final int? apiId;
  final String? ticketNumber;
  final String typeKey;
  final String subject;
  final String details;
  final String? relatedOrderId;
  final DateTime createdAt;
  String statusKey;
  final List<String> evidenceImages;
  final List<ComplaintReply> replies;

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

  factory Complaint.fromApiJson(Map<String, dynamic> json) {
    final map = _unwrapTicket(json) ?? json;
    final apiId = int.tryParse('${map['id'] ?? ''}');
    final category = '${map['category'] ?? 'general_inquiry'}';
    final status = '${map['status'] ?? 'open'}';
    final order = map['order'];
    final orderId = order is Map ? order['id'] : map['order_id'];

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
      evidenceImages: _parseEvidence(map),
      replies: _parseReplies(map),
    );
  }

  static Map<String, dynamic>? _unwrapTicket(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
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
        final url = _resolveImageUrl(
          attachment['url']?.toString(),
          attachment['file_name']?.toString(),
        );
        if (url.isNotEmpty) urls.add(url);
      }
    }

    return urls;
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
