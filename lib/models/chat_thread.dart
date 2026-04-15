import 'chat_message.dart';

class ChatThread {
  final String id;
  final String storeKey;
  final List<ChatMessage> messages;
  int unreadCount;

  ChatThread({
    required this.id,
    required this.storeKey,
    List<ChatMessage>? messages,
    this.unreadCount = 0,
  }) : messages = messages ?? [];

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

