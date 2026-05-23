import 'package:flutter/material.dart';
import 'dart:io';
import 'l10n/app_strings.dart';
import 'models/complaint.dart';
import 'models/complaints_manager.dart';
import 'widgets/app_back_button.dart';
import 'widgets/new_complaint_dialog.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ComplaintsManager _manager = ComplaintsManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('complaint_title'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => NewComplaintDialog.show(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('complaint_new')),
                    ),
                    const SizedBox(height: 20),
                    if (_manager.complaints.isEmpty) _buildEmptyState() else _buildComplaintsList(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppBackTextButton(
          label: context.tr('back'),
          onPressed: () => Navigator.pop(context),
        ),
        const Text('Trendy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.feedback_outlined, size: 60, color: Colors.white30),
          const SizedBox(height: 14),
          Text(context.tr('complaint_empty'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(context.tr('complaint_empty_sub'), style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildComplaintsList() {
    return Column(
      children: _manager.complaints.map(_buildComplaintCard).toList(),
    );
  }

  Widget _buildComplaintCard(Complaint c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(context.tr(c.statusKey), style: const TextStyle(color: const Color(0xFF3B82F6), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.details, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(context.tr(c.typeKey), style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (c.relatedOrderId != null) ...[
            const SizedBox(height: 4),
            Text(
              '${context.tr('complaint_related_order')}: #${c.relatedOrderId}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if (c.evidenceImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.evidenceImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final path = c.evidenceImages[i];
                  final isWeb = path.startsWith('http://') || path.startsWith('https://');
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isWeb
                        ? Image.network(
                            path,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                            ),
                          )
                        : Image.file(
                            File(path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...c.replies.map(
              (r) => Text(
                '${r.isFromUser ? context.tr('you_label') : context.tr('support_label')}: ${r.message}',
                style: TextStyle(color: r.isFromUser ? Colors.white70 : Colors.greenAccent, fontSize: 12),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showReplyDialog(c.id),
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: Text(context.tr('add_reply')),
                ),
                if (c.statusKey != 'complaint_status_closed')
                  TextButton.icon(
                    onPressed: () => _manager.closeComplaint(c.id),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(context.tr('close_complaint')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String complaintId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        title: Text(context.tr('add_reply'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: context.tr('reply_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              _manager.addReply(complaintId: complaintId, message: controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(context.tr('save_changes')),
          ),
        ],
      ),
    );
  }

}
