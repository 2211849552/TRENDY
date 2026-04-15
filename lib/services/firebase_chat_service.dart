import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class FirebaseChatService {
  FirebaseChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  String threadIdForStore(String storeKey) {
    final uid = _uid;
    if (uid == null) return 'anon_$storeKey';
    return '${uid}_$storeKey';
  }

  DocumentReference<Map<String, dynamic>> threadDoc(String storeKey) {
    final id = threadIdForStore(storeKey);
    return _db.collection('chatThreads').doc(id);
  }

  DocumentReference<Map<String, dynamic>> threadDocById(String threadId) {
    return _db.collection('chatThreads').doc(threadId);
  }

  CollectionReference<Map<String, dynamic>> messagesCol(String storeKey) {
    return threadDoc(storeKey).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> messagesColByThreadId(String threadId) {
    return threadDocById(threadId).collection('messages');
  }

  Future<void> ensureThreadExists({
    required String storeKey,
    required String storeName,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final doc = threadDoc(storeKey);
    await doc.set(
      {
        'id': doc.id,
        'storeKey': storeKey,
        'storeName': storeName,
        'customerUid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageText': null,
        'lastMessageAt': null,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<ChatMessage>> watchMessages(String storeKey) {
    return messagesCol(storeKey)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return ChatMessage(
          id: d.id,
          threadId: threadIdForStore(storeKey),
          sender: (data['sender'] as String) == 'store'
              ? ChatSender.store
              : ChatSender.customer,
          text: (data['text'] as String?) ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0),
        );
      }).toList();
    });
  }

  Stream<List<ChatMessage>> watchMessagesByThreadId(String threadId) {
    return messagesColByThreadId(threadId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return ChatMessage(
          id: d.id,
          threadId: threadId,
          sender: (data['sender'] as String) == 'store'
              ? ChatSender.store
              : ChatSender.customer,
          text: (data['text'] as String?) ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0),
        );
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String storeKey,
    required ChatSender sender,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final msg = {
      'sender': sender == ChatSender.store ? 'store' : 'customer',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'senderUid': uid,
    };

    final thread = threadDoc(storeKey);
    await _db.runTransaction((tx) async {
      tx.set(
        thread,
        {
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessageText': trimmed,
          'lastMessageAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(messagesCol(storeKey).doc(), msg);
    });
  }

  Future<void> sendMessageByThreadId({
    required String threadId,
    required String storeKey,
    required ChatSender sender,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final msg = {
      'sender': sender == ChatSender.store ? 'store' : 'customer',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'senderUid': uid,
    };

    final thread = threadDocById(threadId);
    await _db.runTransaction((tx) async {
      tx.set(
        thread,
        {
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessageText': trimmed,
          'lastMessageAt': FieldValue.serverTimestamp(),
          if (sender == ChatSender.store) 'storeUid': uid,
        },
        SetOptions(merge: true),
      );
      tx.set(messagesColByThreadId(threadId).doc(), msg);
    });
  }
}

