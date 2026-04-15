import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../services/firebase_chat_service.dart';
import '../services/firebase_state.dart';

class ChatWithStoreScreen extends StatefulWidget {
  final String storeKey;
  const ChatWithStoreScreen({super.key, required this.storeKey});

  @override
  State<ChatWithStoreScreen> createState() => _ChatWithStoreScreenState();
}

class _ChatWithStoreScreenState extends State<ChatWithStoreScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FirebaseChatService _chat = FirebaseChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.ensureThreadExists(
        storeKey: widget.storeKey,
        storeName: context.tr(widget.storeKey),
      );
    });
  }

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
    _chat.sendMessage(
      storeKey: widget.storeKey,
      sender: ChatSender.customer,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseState().ready.value) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr(widget.storeKey), style: GoogleFonts.cairo()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              context.tr('firebase_not_ready'),
              style: GoogleFonts.cairo(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.storeKey), style: GoogleFonts.cairo()),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chat.watchMessages(widget.storeKey),
              builder: (context, snap) {
                final messages = snap.data ?? const <ChatMessage>[];
                WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.sender == ChatSender.customer;
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
                    textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                  icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
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
    final bg = isMe ? Colors.blueAccent.withOpacity(0.25) : Colors.white.withOpacity(0.08);
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

