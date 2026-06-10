import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../locale/app_locale.dart';
import '../models/auth_session.dart';
import '../models/chat_manager.dart';
import '../models/chat_message.dart';
import '../services/api/api_exception.dart';
import '../services/api/chat_api.dart';
import '../services/firebase_availability.dart';
import '../services/firebase_chat_service.dart';

class ChatWithStoreScreen extends StatefulWidget {
  final String storeKey;

  /// معرف المتجر في API — إن وُجد والمستخدم مسجّل، تُستخدم محادثة الخادم.
  final int? storeId;

  /// اسم المتجر للعرض (للمتاجر القادمة من API).
  final String? storeDisplayName;

  const ChatWithStoreScreen({
    super.key,
    required this.storeKey,
    this.storeId,
    this.storeDisplayName,
  });

  @override
  State<ChatWithStoreScreen> createState() => _ChatWithStoreScreenState();
}

class _ChatWithStoreScreenState extends State<ChatWithStoreScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ChatManager _localChat = ChatManager();
  final ChatApi _chatApi = ChatApi();
  FirebaseChatService? _firebaseChat;

  // حالة محادثة API
  int? _conversationId;
  List<StoreChatMessage> _apiMessages = const [];
  Timer? _pollTimer;
  bool _apiLoading = false;
  String? _apiError;
  bool _sending = false;

  /// تُستخدم محادثة API عندما يكون المتجر من الخادم والمستخدم مسجلاً.
  bool get _useApiChat =>
      widget.storeId != null && AuthSession.instance.isAuthenticated;

  bool get _useFirebase => !_useApiChat && isFirebaseChatAvailable;

  FirebaseChatService get _firebase {
    return _firebaseChat ??= FirebaseChatService();
  }

  String get _lang => AppLocale.instance.locale.languageCode;

  String get _storeTitle =>
      widget.storeDisplayName?.trim().isNotEmpty == true
          ? widget.storeDisplayName!.trim()
          : context.tr(widget.storeKey);

  @override
  void initState() {
    super.initState();
    if (_useApiChat) {
      _startApiChat();
    } else if (!_useFirebase) {
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
      storeName: _storeTitle,
    );
  }

  Future<void> _startApiChat() async {
    setState(() {
      _apiLoading = true;
      _apiError = null;
    });
    try {
      final conversationId = await _chatApi.startStoreChat(widget.storeId!);
      if (!mounted) return;
      _conversationId = conversationId;
      await _refreshApiMessages();
      // تحديث دوري كل 5 ثوانٍ لجلب ردود المتجر
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshApiMessages(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = context.tr('chat_load_failed'));
    } finally {
      if (mounted) setState(() => _apiLoading = false);
    }
  }

  Future<void> _refreshApiMessages() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      final messages = await _chatApi.fetchMessages(conversationId);
      if (!mounted) return;
      final changed = messages.length != _apiMessages.length ||
          (messages.isNotEmpty &&
              _apiMessages.isNotEmpty &&
              messages.last.id != _apiMessages.last.id);
      setState(() => _apiMessages = messages);
      if (changed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
      }
    } catch (_) {
      // فشل التحديث الدوري لا يقطع المحادثة.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
    if (text.isEmpty || _sending) return;
    _composer.clear();

    if (_useApiChat) {
      final conversationId = _conversationId;
      if (conversationId == null) return;
      setState(() => _sending = true);
      try {
        await _chatApi.sendMessage(conversationId, text);
        await _refreshApiMessages();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message, style: GoogleFonts.cairo())),
        );
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

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
        title: Text(_storeTitle, style: GoogleFonts.cairo()),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_useApiChat) return _buildApiMessages();
    if (_useFirebase) return _buildFirebaseMessages();
    return _buildLocalMessages();
  }

  Widget _buildApiMessages() {
    if (_apiLoading && _apiMessages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }
    if (_apiError != null && _apiMessages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _apiError!,
                style: GoogleFonts.cairo(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _startApiChat,
                child: Text(context.tr('chat_retry'), style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }
    if (_apiMessages.isEmpty) {
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
      itemCount: _apiMessages.length,
      itemBuilder: (context, index) {
        final m = _apiMessages[index];
        return _RawBubble(text: m.text, isMe: m.isMine);
      },
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
        return _RawBubble(text: m.text, isMe: isMe);
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
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }
}

class _RawBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _RawBubble({required this.text, required this.isMe});

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
          text,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
