import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/push_token_store.dart';
import '../services/api/api_exception.dart';
import '../services/api/fcm_api.dart';
import '../services/api/notifications_api.dart';
import 'notification_item.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static const _enabledKey = 'notifications_enabled';

  final NotificationsApi _api = NotificationsApi();
  final FcmApi _fcmApi = FcmApi();
  final List<NotificationItem> _notifications = [];
  bool _notificationsEnabled = true;
  bool _isSyncing = false;
  bool _isUpdatingPreference = false;
  int _serverUnreadCount = 0;
  String? _preferenceError;
  bool _loaded = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isSyncing => _isSyncing;
  bool get isUpdatingPreference => _isUpdatingPreference;
  String? get preferenceError => _preferenceError;

  Future<void> load() async {
    if (_loaded) return;
    await PushTokenStore.instance.load();
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_enabledKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  /// تفعيل/إيقاف الإشعارات — يُحدّث FCM عند توفر توكن الجهاز.
  Future<bool> setNotificationsEnabled(bool value) async {
    if (_isUpdatingPreference) return false;
    if (_notificationsEnabled == value) return true;

    _preferenceError = null;
    _isUpdatingPreference = true;
    notifyListeners();

    try {
      if (AuthSession.instance.isAuthenticated) {
        final token = PushTokenStore.instance.token;
        if (token != null && token.isNotEmpty) {
          if (value) {
            await _fcmApi.registerToken(deviceToken: token);
          } else {
            await _fcmApi.unregisterToken(deviceToken: token);
          }
        }
      }

      _notificationsEnabled = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _preferenceError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _preferenceError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isUpdatingPreference = false;
      notifyListeners();
    }
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount {
    if (_notifications.isNotEmpty) {
      return _notifications.where((n) => !n.isRead).length;
    }
    return _serverUnreadCount;
  }

  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();
    try {
      final result = await _api.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(result.items);
      _serverUnreadCount = result.unreadCount;
    } catch (_) {
      // نُبقي القائمة الحالية عند فشل المزامنة.
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void addNotification(NotificationItem notification) {
    if (!_notificationsEnabled) return;
    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0) return;

    if (!_notifications[i].isRead) {
      _notifications[i].isRead = true;
      notifyListeners();
    }

    final numericId = int.tryParse(id);
    if (numericId != null && AuthSession.instance.isAuthenticated) {
      try {
        await _api.markAsRead(numericId);
      } catch (_) {}
    }
  }

  Future<void> toggleRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0) return;

    final wasRead = _notifications[i].isRead;
    _notifications[i].isRead = !wasRead;
    notifyListeners();

    if (!wasRead) {
      final numericId = int.tryParse(id);
      if (numericId != null && AuthSession.instance.isAuthenticated) {
        try {
          await _api.markAsRead(numericId);
        } catch (_) {}
      }
    }
  }

  Future<void> markAllAsRead() async {
    var changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();

    if (AuthSession.instance.isAuthenticated) {
      try {
        await _api.markAllAsRead();
      } catch (_) {}
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _serverUnreadCount = 0;
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
