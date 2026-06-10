import '../../models/auth_session.dart';
import 'api_client.dart';

/// رسالة محادثة قادمة من API.
class StoreChatMessage {
  const StoreChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final int conversationId;
  final int? senderId;
  final String text;
  final DateTime createdAt;

  /// هل الرسالة من المستخدم الحالي (الزبون)؟
  bool get isMine {
    final myId = AuthSession.instance.user?.id;
    return myId != null && senderId == myId;
  }

  factory StoreChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    int? senderId = int.tryParse('${json['sender_id'] ?? ''}');
    if (senderId == null && sender is Map) {
      senderId = int.tryParse('${sender['id'] ?? ''}');
    }

    return StoreChatMessage(
      id: int.tryParse('${json['id'] ?? ''}') ?? 0,
      conversationId: int.tryParse('${json['conversation_id'] ?? ''}') ?? 0,
      senderId: senderId,
      text: '${json['message_text'] ?? ''}'.trim(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

/// واجهة API نظام المحادثات الموحد (زبون ↔ متجر).
class ChatApi {
  ChatApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// POST /api/orders/chat/store — يبدأ (أو يستأنف) محادثة مع المتجر
  /// ويُرجع معرف المحادثة.
  Future<int> startStoreChat(int storeId) async {
    final json = await _client.postFromRoot(
      '/orders/chat/store',
      body: {'store_id': storeId},
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final id = int.tryParse('${data['id'] ?? ''}');
      if (id != null && id > 0) return id;
    }
    throw const FormatException('لم يُرجع الخادم معرف المحادثة');
  }

  /// GET /api/orders/chat/{id}/messages — أحدث الرسائل (الأقدم أولاً).
  Future<List<StoreChatMessage>> fetchMessages(int conversationId) async {
    final json = await _client.getFromRoot('/orders/chat/$conversationId/messages');
    final rows = json['data'];
    if (rows is! List) return const [];

    final messages = rows
        .whereType<Map<String, dynamic>>()
        .map(StoreChatMessage.fromJson)
        .where((m) => m.id > 0)
        .toList();

    // الخادم يرجع الأحدث أولاً — نعكس لعرض المحادثة تصاعدياً.
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  /// POST /api/orders/chat/{id}/messages — إرسال رسالة نصية.
  Future<StoreChatMessage?> sendMessage(int conversationId, String text) async {
    final json = await _client.postFromRoot(
      '/orders/chat/$conversationId/messages',
      body: {'message_text': text},
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return StoreChatMessage.fromJson(data);
    }
    return null;
  }
}
