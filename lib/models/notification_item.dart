class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final String? targetTab;
  final String? targetOrderId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.targetTab,
    this.targetOrderId,
  });

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
