import 'package:flutter/material.dart';
import 'notification_item.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<NotificationItem> _notifications = [];
  bool _notificationsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled != value) {
      _notificationsEnabled = value;
      notifyListeners();
    }
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(NotificationItem notification) {
    if (!_notificationsEnabled) return; // Block if notifications disabled
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i >= 0 && !_notifications[i].isRead) {
      _notifications[i].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
