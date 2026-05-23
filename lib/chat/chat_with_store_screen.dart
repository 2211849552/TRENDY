import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../locale/app_locale.dart';
import '../models/chat_manager.dart';
import '../models/chat_message.dart';
import '../services/firebase_availability.dart';
import '../services/firebase_chat_service.dart';

class ChatWithStoreScreen extends StatefulWidget {
  final String storeKey;
  const ChatWithStoreScreen({super.key, required this.storeKey});

  @override
  State<ChatWithStoreScreen> createState() => _ChatWithStoreScreenState();
}

class _ChatWithStoreScreenState extends State<ChatWithStoreScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ChatManager _localChat = ChatManager();
  FirebaseChatService? _firebaseChat;

  bool get _useFirebase => isFirebaseChatAvailable;

  FirebaseChatService get _firebase {
    return _firebaseChat ??= FirebaseChatService();
  }

  String get _lang => AppLocale.instance.locale.languageCode;

  @override
  void initState() {
    super.initState();
    if (!_useFirebase) {
      _localChat.threadForStore(widget.storeKey, languageCode: _lang);
      _localChat.refreshWelcomeIfNeeded(widget.storeKey, languageCode: _lang);
      _localChat.markRead(widget.storeKey);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFirebaseThreadIfNeeded());
  }

  void _openFirebaseThreadIfNeeded() {
    if (!_useFirebase) return;
    _firebase.ensureThreadExists(
      storeKey: widget.storeKey,
      storeName: context.tr(widget.storeKey),
    );
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

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();

    if (_useFirebase) {
      try {
        await _firebase.sendMessage(
          storeKey: widget.storeKey,
          sender: ChatSender.customer,
          text: text,
        );
        return;
      } catch (_) {
        // Firebase غير متاح — نكمل بالمحادثة المحلية.
      }
    }

    _localChat.sendCustomerMessage(widget.storeKey, text, languageCode: _lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.storeKey), style: GoogleFonts.cairo()),
      ),
      body: Column(
        children: [
          Expanded(
            child: _useFirebase ? _buildFirebaseMessages() : _buildLocalMessages(),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildFirebaseMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _firebase.watchMessages(widget.storeKey),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.tr('chat_load_failed'),
                style: GoogleFonts.cairo(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final messages = snap.data ?? const <ChatMessage>[];
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
        return _messageList(messages);
      },
    );
  }

  Widget _buildLocalMessages() {
    return ListenableBuilder(
      listenable: _localChat,
      builder: (context, _) {
        final messages = _localChat.messagesForStore(widget.storeKey, languageCode: _lang);
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
        return _messageList(messages);
      },
    );
  }

  Widget _messageList(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          context.tr('chat_start_hint'),
          style: GoogleFonts.cairo(color: Colors.white38, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
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
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
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
                fillColor: Colors.white.withValues(alpha: 0.06),
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
    final bg = isMe ? const Color(0xFF3B82F6).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08);
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
