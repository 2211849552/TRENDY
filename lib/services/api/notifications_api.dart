import '../../models/notification_item.dart';
import 'api_client.dart';

class NotificationsPageResult {
  const NotificationsPageResult({
    required this.items,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int unreadCount;
}

class NotificationsApi {
  NotificationsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/notifications
  Future<NotificationsPageResult> fetchNotifications({int perPage = 30}) async {
    final json = await _client.getFromRoot(
      '/notifications',
      query: {'per_page': '$perPage'},
    );

    final unread = _asInt(json['unread_count']) ?? 0;
    final rows = _readNotificationRows(json['data']);
    final items = rows.map(_fromJson).toList();

    return NotificationsPageResult(items: items, unreadCount: unread);
  }

  /// PATCH /api/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    await _client.patchFromRoot('/notifications/$id/read');
  }

  /// POST /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _client.postFromRoot('/notifications/read-all');
  }

  List<Map<String, dynamic>> _readNotificationRows(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  NotificationItem _fromJson(Map<String, dynamic> json) {
    final typeRaw = '${json['type'] ?? 'general'}'.toLowerCase();
    final type = _mapType(typeRaw);
    final data = json['data'];
    String? targetTab;
    String? targetOrderId;

    if (data is Map) {
      targetTab = data['target_tab']?.toString() ?? data['tab']?.toString();
      targetOrderId = data['order_id']?.toString();
      if (typeRaw.contains('order')) targetTab ??= 'orders';
    }

    return NotificationItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}'.trim(),
      message: '${json['body'] ?? json['message'] ?? ''}'.trim(),
      timestamp: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      isRead: json['read'] == true,
      type: type,
      targetTab: targetTab,
      targetOrderId: targetOrderId,
    );
  }

  NotificationType _mapType(String raw) {
    if (raw.contains('pending')) return NotificationType.orderPending;
    if (raw.contains('ready')) return NotificationType.orderReady;
    if (raw.contains('complete')) return NotificationType.orderCompleted;
    if (raw.contains('wallet')) return NotificationType.walletUpdate;
    if (raw.contains('order')) return NotificationType.orderPending;
    return NotificationType.general;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
