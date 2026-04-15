enum ChatSender {
  customer,
  store,
}

class ChatMessage {
  final String id;
  final String threadId;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });
}

