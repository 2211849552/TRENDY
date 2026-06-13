import 'dart:typed_data';

import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../models/auth_session.dart';
import '../models/complaints_manager.dart';
import '../services/api/api_exception.dart';
import '../services/api/complaints_api.dart';
import 'gradient_button.dart';

/// نافذة إنشاء شكوى — POST /api/complaints (api.md [6]).
class NewComplaintDialog extends StatefulWidget {
  const NewComplaintDialog({super.key, this.scaffoldMessenger});

  final ScaffoldMessengerState? scaffoldMessenger;

  static Future<bool?> show(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    return showDialog<bool?>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) => NewComplaintDialog(scaffoldMessenger: messenger),
    );
  }

  static const _dialogBg = Color(0xFF1E1B4B);
  static const _fieldBg = Color(0xFF1C1A33);
  static const _fieldBorder = Color(0xFF3D5A80);
  static const _primaryBlue = Color(0xFFA855F7);

  /// category API → مفتاح الترجمة
  static const categoryOptions = <String, String>{
    'order_issue': 'complaint_type_order',
    'store_issue': 'complaint_type_store',
    'technical_issue': 'complaint_type_technical',
    'general_inquiry': 'complaint_type_general',
  };

  static const priorityOptions = ['low', 'medium', 'high', 'urgent'];

  @override
  State<NewComplaintDialog> createState() => _NewComplaintDialogState();
}

class _NewComplaintDialogState extends State<NewComplaintDialog> {
  final ComplaintsManager _complaintsManager = ComplaintsManager();
  final ComplaintOrdersApi _ordersApi = ComplaintOrdersApi();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'general_inquiry';
  String _selectedPriority = 'medium';
  String? _selectedOrderId;
  bool _categoryMenuOpen = false;
  bool _priorityMenuOpen = false;
  bool _orderMenuOpen = false;
  bool _loadingOrders = false;
  bool _submitting = false;
  String? _ordersLoadError;
  String? _statusMessage;
  bool _statusIsError = false;
  List<ComplaintOrderOption> _orderOptions = const [];
  List<XFile> _attachments = [];
  List<XFile> _proofImages = [];

  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!AuthSession.instance.isAuthenticated) {
      if (mounted) {
        setState(() {
          _ordersLoadError = null;
          _orderOptions = const [];
        });
      }
      return;
    }

    setState(() {
      _loadingOrders = true;
      _ordersLoadError = null;
    });

    try {
      final orders = await _ordersApi.fetchOrdersForComplaints();
      if (!mounted) return;
      setState(() {
        _orderOptions = orders;
        _selectedOrderId = orders.isNotEmpty ? '${orders.first.id}' : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _orderOptions = const [];
        _selectedOrderId = null;
        _ordersLoadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orderOptions = const [];
        _selectedOrderId = null;
        _ordersLoadError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
      _statusIsError = true;
    });
    final messenger = widget.scaffoldMessenger ?? ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearStatus() {
    if (_statusMessage == null) return;
    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });
  }

  Future<void> _pickImages({required bool proof}) async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      final target = proof ? _proofImages : _attachments;
      final merged = [...target, ...picked];
      if (proof) {
        _proofImages = merged.take(5).toList();
      } else {
        _attachments = merged.take(5).toList();
      }
    });
  }

  void _removeImage({required bool proof, required int index}) {
    setState(() {
      if (proof) {
        _proofImages = List<XFile>.from(_proofImages)..removeAt(index);
      } else {
        _attachments = List<XFile>.from(_attachments)..removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _clearStatus();

    if (!AuthSession.instance.isAuthenticated) {
      _showMessage(context.tr('login_required_complaint'));
      return;
    }

    if (_loadingOrders) {
      await _loadOrders();
      if (!mounted) return;
    }

    if (_ordersLoadError != null) {
      _showMessage(_ordersLoadError!);
      return;
    }

    if (_orderOptions.isEmpty) {
      _showMessage(context.tr('complaint_no_orders'));
      return;
    }

    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();
    if (subject.isEmpty) {
      _showMessage(context.tr('complaint_subject_required'));
      return;
    }
    if (details.isEmpty) {
      _showMessage(context.tr('complaint_details_required'));
      return;
    }

    final orderId = int.tryParse(_selectedOrderId ?? '');
    if (orderId == null || orderId <= 0) {
      _showMessage(context.tr('complaint_order_required'));
      return;
    }

    setState(() => _submitting = true);
    try {
      final ok = await _complaintsManager.submitComplaint(
        category: _selectedCategory,
        subject: subject,
        details: details,
        orderId: orderId,
        priority: _selectedPriority,
        attachments: _attachments,
        proof: _proofImages,
      );
      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }

      _showMessage(_complaintsManager.error ?? context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<({String value, String label})> get _orderPickerOptions {
    return _orderOptions
        .map((o) => (value: '${o.id}', label: o.label))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Dialog(
            backgroundColor: NewComplaintDialog._dialogBg,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenW > 520 ? 440 : screenW - 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: IconButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white38, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                    Text(
                      context.tr('complaint_create_title'),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('complaint_create_subtitle'),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(fontSize: 13, color: Colors.white54, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    if (_statusMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_statusIsError ? Colors.redAccent : Colors.greenAccent)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _statusIsError ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                        child: Text(
                          _statusMessage!,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            color: _statusIsError ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _buildPicker(
                      label: context.tr('complaint_type'),
                      isOpen: _categoryMenuOpen,
                      selectedLabel: context.tr(
                        NewComplaintDialog.categoryOptions[_selectedCategory]!,
                      ),
                      onToggle: () => setState(() {
                        _priorityMenuOpen = false;
                        _orderMenuOpen = false;
                        _categoryMenuOpen = !_categoryMenuOpen;
                      }),
                      options: NewComplaintDialog.categoryOptions.entries
                          .map((e) => (value: e.key, label: context.tr(e.value)))
                          .toList(),
                      selectedValue: _selectedCategory,
                      onSelect: (v) => setState(() {
                        _selectedCategory = v;
                        _categoryMenuOpen = false;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildPicker(
                      label: context.tr('complaint_related_order'),
                      isOpen: _orderMenuOpen,
                      enabled: !_loadingOrders && !_submitting && _orderOptions.isNotEmpty,
                      selectedLabel: _loadingOrders
                          ? context.tr('loading')
                          : _orderOptions.isEmpty
                              ? context.tr('complaint_no_orders')
                              : _orderPickerOptions
                                      .where((o) => o.value == _selectedOrderId)
                                      .map((o) => o.label)
                                      .firstOrNull ??
                                  context.tr('complaint_order_required'),
                      onToggle: () => setState(() {
                        _categoryMenuOpen = false;
                        _priorityMenuOpen = false;
                        _orderMenuOpen = !_orderMenuOpen;
                      }),
                      options: _orderPickerOptions,
                      selectedValue: _selectedOrderId ?? '',
                      onSelect: (v) => setState(() {
                        _selectedOrderId = v;
                        _orderMenuOpen = false;
                      }),
                    ),
                    if (_ordersLoadError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _ordersLoadError!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: _loadingOrders || _submitting ? null : _loadOrders,
                          child: Text(context.tr('retry')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildPicker(
                      label: context.tr('complaint_priority'),
                      isOpen: _priorityMenuOpen,
                      selectedLabel: context.tr('complaint_priority_$_selectedPriority'),
                      onToggle: () => setState(() {
                        _categoryMenuOpen = false;
                        _orderMenuOpen = false;
                        _priorityMenuOpen = !_priorityMenuOpen;
                      }),
                      options: NewComplaintDialog.priorityOptions
                          .map((p) => (value: p, label: context.tr('complaint_priority_$p')))
                          .toList(),
                      selectedValue: _selectedPriority,
                      onSelect: (v) => setState(() {
                        _selectedPriority = v;
                        _priorityMenuOpen = false;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(context.tr('complaint_subject')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _subjectController,
                      hint: context.tr('complaint_subject_hint'),
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(context.tr('complaint_details')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _detailsController,
                      hint: context.tr('complaint_details_hint'),
                      maxLines: 4,
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: 16),
                    _buildImageSection(
                      title: context.tr('complaint_attachments'),
                      hint: context.tr('complaint_attachments_hint'),
                      files: _attachments,
                      proof: false,
                    ),
                    const SizedBox(height: 16),
                    _buildImageSection(
                      title: context.tr('complaint_proof'),
                      hint: context.tr('complaint_proof_hint'),
                      files: _proofImages,
                      proof: true,
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _submitting
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : GradientButton(
                              onPressed: _submit,
                              label: context.tr('send_complaint'),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String hint,
    required List<XFile> files,
    required bool proof,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel(title),
        const SizedBox(height: 6),
        Text(
          hint,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < files.length; i++)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _imageThumb(files[i]),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    left: -6,
                    child: GestureDetector(
                      onTap: _submitting ? null : () => _removeImage(proof: proof, index: i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (files.length < 5)
              InkWell(
                onTap: _submitting ? null : () => _pickImages(proof: proof),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: NewComplaintDialog._fieldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NewComplaintDialog._fieldBorder),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white54),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _imageThumb(XFile file) {
    if (kIsWeb) {
      return FutureBuilder<List<int>>(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ColoredBox(
              color: NewComplaintDialog._fieldBg,
              child: Icon(Icons.image_outlined, color: Colors.white38),
            );
          }
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            fit: BoxFit.cover,
            width: 64,
            height: 64,
          );
        },
      );
    }
    return Image.file(
      File(file.path),
      fit: BoxFit.cover,
      width: 64,
      height: 64,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.white38),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: NewComplaintDialog._fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: NewComplaintDialog._fieldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: NewComplaintDialog._primaryBlue, width: 1.2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required bool isOpen,
    required String selectedLabel,
    required VoidCallback onToggle,
    required List<({String value, String label})> options,
    required String selectedValue,
    required void Function(String value) onSelect,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onToggle : null,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              decoration: BoxDecoration(
                color: NewComplaintDialog._fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOpen ? NewComplaintDialog._primaryBlue : NewComplaintDialog._fieldBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          color: enabled ? Colors.white : Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: NewComplaintDialog._fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NewComplaintDialog._fieldBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  InkWell(
                    onTap: () => onSelect(options[i].value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[i].label,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: options[i].value == selectedValue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (options[i].value == selectedValue)
                            const Icon(Icons.check, color: Colors.white, size: 18)
                          else
                            const SizedBox(width: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
