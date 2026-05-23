import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../services/firebase_chat_service.dart';

class StoreThreadChatScreen extends StatefulWidget {
  final String threadId;
  final String storeKey;
  final String customerUid;

  const StoreThreadChatScreen({
    super.key,
    required this.threadId,
    required this.storeKey,
    required this.customerUid,
  });

  @override
  State<StoreThreadChatScreen> createState() => _StoreThreadChatScreenState();
}

class _StoreThreadChatScreenState extends State<StoreThreadChatScreen> {
  final FirebaseChatService _chat = FirebaseChatService();
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _send() {
    final text = _composer.text;
    _composer.clear();
    _chat.sendMessageByThreadId(
      threadId: widget.threadId,
      storeKey: widget.storeKey,
      sender: ChatSender.store,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      appBar: AppBar(
        title: Text(context.tr('store_chat_title'), style: GoogleFonts.cairo()),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chat.watchMessagesByThreadId(widget.threadId),
              builder: (context, snap) {
                final messages = snap.data ?? const <ChatMessage>[];
                WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.sender == ChatSender.store;
                    return _Bubble(message: m, isMe: isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composer,
                    style: GoogleFonts.cairo(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: context.tr('chat_hint'),
                      hintStyle: GoogleFonts.cairo(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded, color: const Color(0xFF3B82F6)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isMe ? Colors.greenAccent.withOpacity(0.18) : Colors.white.withOpacity(0.08);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 14),
    );

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

