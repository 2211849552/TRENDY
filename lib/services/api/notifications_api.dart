import '../../models/notification_item.dart';
import 'api_client.dart';
import 'customer_api_paths.dart';

class NotificationsPageResult {
  const NotificationsPageResult({
    required this.items,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int unreadCount;
}

/// إشعارات الزبون — انظر api.md [20].
class NotificationsApi {
  NotificationsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/notifications — يجلب كل الصفحات المتاحة.
  Future<NotificationsPageResult> fetchNotifications({int perPage = 50}) async {
    final allItems = <NotificationItem>[];
    var page = 1;
    var unread = 0;
    var lastPage = 1;

    do {
      final json = await _client.getFromRoot(
        CustomerApiPaths.notifications,
        query: {'page': '$page', 'per_page': '$perPage'},
      );

      if (page == 1) {
        unread = _asInt(json['unread_count']) ?? 0;
      }

      final rows = _readNotificationRows(json['data']);
      allItems.addAll(rows.map(_fromJson));

      final meta = _readMeta(json['data']);
      lastPage = meta?['last_page'] as int? ?? 1;
      page++;
    } while (page <= lastPage);

    return NotificationsPageResult(items: allItems, unreadCount: unread);
  }

  Map<String, dynamic>? _readMeta(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final meta = raw['meta'];
      if (meta is Map<String, dynamic>) {
        return {
          'last_page': _asInt(meta['last_page']) ?? 1,
        };
      }
    }
    return null;
  }

  /// GET /api/notifications/{id}
  Future<NotificationItem> fetchNotification(int id) async {
    final json = await _client.getFromRoot(CustomerApiPaths.notification(id));
    final data = json['data'];
    if (data is Map<String, dynamic>) return _fromJson(data);
    return _fromJson(json);
  }

  /// PATCH /api/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    await _client.patchFromRoot(CustomerApiPaths.notificationRead(id));
  }

  /// POST /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _client.postFromRoot(CustomerApiPaths.notificationsReadAll);
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
    String? orderNumber;

    if (data is Map) {
      targetTab = data['target_tab']?.toString() ?? data['tab']?.toString();
      targetOrderId = data['order_id']?.toString();
      orderNumber = data['order_number']?.toString();
      if (typeRaw.contains('order')) targetTab ??= 'orders';
    } else {
      orderNumber = null;
    }

    final readAt = json['read_at'];
    final isRead = json['read'] == true ||
        json['is_read'] == true ||
        (readAt != null && '$readAt'.trim().isNotEmpty);

    return NotificationItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}'.trim(),
      message: '${json['body'] ?? json['message'] ?? ''}'.trim(),
      timestamp: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      isRead: isRead,
      type: type,
      targetTab: targetTab,
      targetOrderId: targetOrderId,
      orderNumber: orderNumber,
    );
  }

  NotificationType _mapType(String raw) {
    if (raw.contains('complaint')) return NotificationType.general;
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
