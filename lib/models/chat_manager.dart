import 'dart:math';

import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import 'chat_message.dart';
import 'chat_thread.dart';

class ChatManager extends ChangeNotifier {
  static final ChatManager _instance = ChatManager._();
  factory ChatManager() => _instance;
  ChatManager._();

  final Map<String, ChatThread> _threadsByStore = {};

  List<ChatThread> get threads {
    final list = _threadsByStore.values.toList();
    list.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  int get totalUnread =>
      _threadsByStore.values.fold<int>(0, (sum, t) => sum + t.unreadCount);

  /// يحدّث رسالة الترحيب إن كانت المحادثة جديدة وباللغة الخاطئة.
  void refreshWelcomeIfNeeded(String storeKey, {String? languageCode}) {
    final thread = _threadsByStore[storeKey];
    if (thread == null || thread.messages.length != 1) return;
    final first = thread.messages.first;
    if (first.sender != ChatSender.store) return;

    final lang = languageCode ?? 'ar';
    final welcome = AppStrings.formatLang(lang, 'chat_welcome', params: {
      'store': AppStrings.formatLang(lang, storeKey),
    });
    if (first.text == welcome) return;

    thread.messages[0] = ChatMessage(
      id: first.id,
      threadId: first.threadId,
      sender: first.sender,
      text: welcome,
      createdAt: first.createdAt,
    );
    notifyListeners();
  }

  ChatThread threadForStore(String storeKey, {String? languageCode}) {
    final existing = _threadsByStore[storeKey];
    if (existing != null) {
      refreshWelcomeIfNeeded(storeKey, languageCode: languageCode);
      return existing;
    }

    final thread = ChatThread(id: _newId('th'), storeKey: storeKey);
    _threadsByStore[storeKey] = thread;

    final lang = languageCode ?? 'ar';
    final welcome = AppStrings.formatLang(lang, 'chat_welcome', params: {
      'store': AppStrings.formatLang(lang, storeKey),
    });
    thread.messages.add(
      ChatMessage(
        id: _newId('m'),
        threadId: thread.id,
        sender: ChatSender.store,
        text: welcome,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
    return thread;
  }

  List<ChatMessage> messagesForStore(String storeKey, {String? languageCode}) {
    return threadForStore(storeKey, languageCode: languageCode).messages;
  }

  void markRead(String storeKey) {
    final thread = _threadsByStore[storeKey];
    if (thread == null) return;
    if (thread.unreadCount == 0) return;
    thread.unreadCount = 0;
    notifyListeners();
  }

  void sendCustomerMessage(String storeKey, String text, {String? languageCode}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final thread = threadForStore(storeKey, languageCode: languageCode);
    thread.messages.add(
      ChatMessage(
        id: _newId('m'),
        threadId: thread.id,
        sender: ChatSender.customer,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();

    _simulateStoreReply(storeKey, trimmed, languageCode: languageCode);
  }

  void _simulateStoreReply(String storeKey, String customerText, {String? languageCode}) {
    final thread = threadForStore(storeKey, languageCode: languageCode);
    final replyText = _pickReply(customerText);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      thread.messages.add(
        ChatMessage(
          id: _newId('m'),
          threadId: thread.id,
          sender: ChatSender.store,
          text: replyText,
          createdAt: DateTime.now(),
        ),
      );
      thread.unreadCount += 1;
      notifyListeners();
    });
  }

  String _pickReply(String text) {
    final t = text.toLowerCase();
    if (t.contains('سعر') || t.contains('price')) {
      return 'أكيد—وش اسم/كود المنتج؟';
    }
    if (t.contains('متوفر') || t.contains('available') || t.contains('stock')) {
      return 'نعم متوفر غالباً. أي لون/مقاس تحتاج؟';
    }
    if (t.contains('شحن') || t.contains('delivery')) {
      return 'نقدر نرتّب التوصيل داخل المدينة. اكتب موقعك التقريبي.';
    }
    const replies = [
      'أهلاً! كيف نقدر نساعدك؟',
      'تمام، أعطني تفاصيل أكثر لو سمحت.',
      'تم—بنراجع ونرد عليك الآن.',
    ];
    return replies[Random().nextInt(replies.length)];
  }

  String _newId(String prefix) {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(999999);
    return '${prefix}_$ms$r';
  }
}

