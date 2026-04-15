import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import 'chat_with_store_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_state.dart';

class ChatThreadsScreen extends StatelessWidget {
  const ChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseState().ready.value) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('chat_title'), style: GoogleFonts.cairo()),
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final stream = uid == null
        ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
            .collection('chatThreads')
            .where('customerUid', isEqualTo: uid)
            .orderBy('updatedAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chat_title'), style: GoogleFonts.cairo()),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                context.tr('chat_empty'),
                style: GoogleFonts.cairo(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final storeKey = (data['storeKey'] as String?) ?? '';
              final lastText = (data['lastMessageText'] as String?) ?? '';
              return _ThreadTile(
                storeKey: storeKey,
                lastText: lastText,
              );
            },
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final String storeKey;
  final String lastText;
  const _ThreadTile({required this.storeKey, required this.lastText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatWithStoreScreen(storeKey: storeKey),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E5BB3).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.08),
              child: const Icon(Icons.storefront_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(storeKey),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

