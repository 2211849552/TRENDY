import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'l10n/app_strings.dart';
import 'models/complaint.dart';
import 'models/complaints_manager.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ComplaintsManager _manager = ComplaintsManager();
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';
  String _statusFilter = 'all_statuses';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
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
                      onPressed: () => _showNewComplaintDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('complaint_new')),
                    ),
                    const SizedBox(height: 14),
                    _buildFilterBar(),
                    const SizedBox(height: 20),
                    if (_visibleComplaints.isEmpty) _buildEmptyState() else _buildComplaintsList(),
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
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
          label: Text(context.tr('back'), style: const TextStyle(color: Colors.white70)),
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
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
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
      children: _visibleComplaints.map(_buildComplaintCard).toList(),
    );
  }

  List<Complaint> get _visibleComplaints {
    final q = _searchQuery.trim().toLowerCase();
    return _manager.complaints.where((c) {
      final statusMatch = _statusFilter == 'all_statuses' || c.statusKey == _statusFilter;
      final queryMatch = q.isEmpty ||
          c.subject.toLowerCase().contains(q) ||
          c.details.toLowerCase().contains(q);
      return statusMatch && queryMatch;
    }).toList();
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: context.tr('search_complaints'),
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E5BB3).withOpacity(0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 165,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5BB3).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: const Color(0xFF121E36),
              isExpanded: true,
              items: const ['all_statuses', 'complaint_status_open', 'complaint_status_closed']
                  .map((s) => DropdownMenuItem(value: s, child: Text(context.tr(s), style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _statusFilter = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Complaint c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.12),
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
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(context.tr(c.statusKey), style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.details, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(context.tr(c.typeKey), style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
        backgroundColor: const Color(0xFF121E36),
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

  void _showNewComplaintDialog(BuildContext context) {
    String selectedTypeKey = 'complaint_type_general';
    final subjectController = TextEditingController();
    final detailsController = TextEditingController();
    final imageController = TextEditingController();
    final evidenceImages = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF121E36),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('complaint_new'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 14),
                _buildDropdownField(
                  value: selectedTypeKey,
                  items: const [
                    'complaint_type_general',
                    'complaint_type_technical',
                    'complaint_type_order',
                    'complaint_type_store',
                  ],
                  labelBuilder: (k) => context.tr(k),
                  onChanged: (v) => setDialogState(() => selectedTypeKey = v ?? selectedTypeKey),
                ),
                const SizedBox(height: 12),
                _buildTextField(hint: context.tr('complaint_subject_hint'), controller: subjectController),
                const SizedBox(height: 12),
                _buildTextField(hint: context.tr('complaint_details_hint'), maxLines: 4, controller: detailsController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(hint: context.tr('complaint_evidence_hint'), controller: imageController),
                    ),
                    IconButton(
                      onPressed: () {
                        final v = imageController.text.trim();
                        if (v.isEmpty) return;
                        setDialogState(() {
                          evidenceImages.add(v);
                          imageController.clear();
                        });
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final f = await _picker.pickImage(source: ImageSource.camera);
                        if (f == null) return;
                        setDialogState(() => evidenceImages.add(f.path));
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text(context.tr('camera')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final f = await _picker.pickImage(source: ImageSource.gallery);
                        if (f == null) return;
                        setDialogState(() => evidenceImages.add(f.path));
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(context.tr('gallery')),
                    ),
                  ],
                ),
                if (evidenceImages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: evidenceImages
                        .map(
                          (e) => Chip(
                            label: Text(context.tr('image_label')),
                            onDeleted: () => setDialogState(() => evidenceImages.remove(e)),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty || detailsController.text.trim().isEmpty) return;
                      _manager.addComplaint(
                        Complaint(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          typeKey: selectedTypeKey,
                          subject: subjectController.text.trim(),
                          details: detailsController.text.trim(),
                          createdAt: DateTime.now(),
                          statusKey: 'complaint_status_open',
                          evidenceImages: evidenceImages,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Text(context.tr('send_complaint')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, int maxLines = 1, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String Function(String) labelBuilder,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF121E36),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e), style: const TextStyle(color: Colors.white))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
