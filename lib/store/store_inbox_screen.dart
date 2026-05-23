import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../services/store_identity_service.dart';
import '../services/firebase_state.dart';
import 'store_thread_chat_screen.dart';

class StoreInboxScreen extends StatelessWidget {
  const StoreInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseState().ready.value) {
      return Scaffold(
        backgroundColor: const Color(0xFF121026),
        appBar: AppBar(
          title: Text(context.tr('store_inbox_title'), style: GoogleFonts.cairo()),
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

    final storeKeyStream = StoreIdentityService().watchStoreKey();

    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      appBar: AppBar(
        title: Text(context.tr('store_inbox_title'), style: GoogleFonts.cairo()),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<String?>(
        stream: storeKeyStream,
        builder: (context, storeSnap) {
          final storeKey = storeSnap.data;
          if (storeKey == null || storeKey.isEmpty) {
            return Center(
              child: Text(
                context.tr('store_not_linked'),
                style: GoogleFonts.cairo(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          final stream = FirebaseFirestore.instance
              .collection('chatThreads')
              .where('storeKey', isEqualTo: storeKey)
              .orderBy('updatedAt', descending: true)
              .snapshots();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    context.tr('store_inbox_empty'),
                    style: GoogleFonts.cairo(color: Colors.white70),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data();
                  final lastText = (data['lastMessageText'] as String?) ?? '';
                  final customerUid = (data['customerUid'] as String?) ?? '';
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreThreadChatScreen(
                            threadId: d.id,
                            storeKey: storeKey,
                            customerUid: customerUid,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            child: const Icon(Icons.person_outline, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${context.tr('customer')} $customerUid',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
                          const Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

