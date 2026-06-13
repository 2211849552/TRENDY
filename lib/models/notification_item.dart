class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final String? targetTab;
  final String? targetOrderId;
  final String? orderNumber;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.targetTab,
    this.targetOrderId,
    this.orderNumber,
  });

  bool get isOrderRelated =>
      (targetOrderId != null && targetOrderId!.isNotEmpty) ||
      (orderNumber != null && orderNumber!.isNotEmpty) ||
      type == NotificationType.orderPending ||
      type == NotificationType.orderReady ||
      type == NotificationType.orderCompleted;

  String? get orderLabel {
    if (orderNumber != null && orderNumber!.trim().isNotEmpty) {
      return orderNumber!.trim();
    }
    if (targetOrderId != null && targetOrderId!.trim().isNotEmpty) {
      return '#${targetOrderId!.trim()}';
    }
    return null;
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum NotificationType { orderPending, orderReady, orderCompleted, walletUpdate, general }
