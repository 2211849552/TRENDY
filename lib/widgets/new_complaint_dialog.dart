import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/auth_session.dart';
import '../models/complaints_manager.dart';
import '../services/api/complaints_api.dart';
import 'gradient_button.dart';

/// نافذة إنشاء شكوى جديدة — مطابقة لتصميم النموذج (قائمة نوع الشكوى + الطلب المرتبط).
class NewComplaintDialog extends StatefulWidget {
  const NewComplaintDialog({super.key});

  /// يُعيد `true` عند الإرسال بنجاح، `false` عند الفشل، `null` عند الإغلاق.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const NewComplaintDialog(),
    );
  }

  static const _dialogBg = Color(0xFF1E1B4B);
  static const _fieldBg = Color(0xFF1C1A33);
  static const _fieldBorder = Color(0xFF3D5A80);
  static const _primaryBlue = Color(0xFFA855F7);

  static const _typeKeys = [
    'complaint_type_order',
    'complaint_type_store',
    'complaint_type_technical',
    'complaint_type_general',
  ];

  static const _noneOrder = '__none__';

  @override
  State<NewComplaintDialog> createState() => _NewComplaintDialogState();
}

class _NewComplaintDialogState extends State<NewComplaintDialog> {
  final ComplaintsManager _complaintsManager = ComplaintsManager();
  final ComplaintOrdersApi _ordersApi = ComplaintOrdersApi();

  String _selectedTypeKey = 'complaint_type_general';
  String _selectedOrderKey = NewComplaintDialog._noneOrder;
  bool _typeMenuOpen = false;
  bool _orderMenuOpen = false;
  bool _loadingOrders = false;
  bool _submitting = false;
  List<ComplaintOrderOption> _orderOptions = const [];

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
    if (!AuthSession.instance.isAuthenticated) return;
    setState(() => _loadingOrders = true);
    try {
      final orders = await _ordersApi.fetchOrdersForComplaints();
      if (!mounted) return;
      setState(() {
        _orderOptions = orders;
        if (orders.isNotEmpty && _selectedOrderKey == NewComplaintDialog._noneOrder) {
          _selectedOrderKey = '${orders.first.id}';
        }
      });
    } catch (_) {
      // يُعرض للمستخدم عند الإرسال إن لم يُختر طلب.
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _closeMenus() {
    if (_typeMenuOpen || _orderMenuOpen) {
      setState(() {
        _typeMenuOpen = false;
        _orderMenuOpen = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!AuthSession.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('login_required_complaint'))),
      );
      return;
    }

    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();
    if (subject.isEmpty || details.isEmpty) return;

    final orderId = int.tryParse(_selectedOrderKey);
    if (orderId == null || orderId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('complaint_order_required'))),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await _complaintsManager.submitComplaint(
      typeKey: _selectedTypeKey,
      subject: subject,
      details: details,
      orderId: orderId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('complaint_sent'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_complaintsManager.error ?? context.tr('error_generic'))),
      );
    }
  }

  List<({String value, String label})> get _orderPickerOptions {
    final options = <({String value, String label})>[
      (value: NewComplaintDialog._noneOrder, label: context.tr('complaint_no_order')),
    ];
    for (final o in _orderOptions) {
      options.add((value: '${o.id}', label: o.label));
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: NewComplaintDialog._dialogBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: GestureDetector(
          onTap: _closeMenus,
          behavior: HitTestBehavior.translucent,
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
                  _buildPicker(
                    label: context.tr('complaint_type'),
                    isOpen: _typeMenuOpen,
                    selectedLabel: context.tr(_selectedTypeKey),
                    onToggle: () => setState(() {
                      _orderMenuOpen = false;
                      _typeMenuOpen = !_typeMenuOpen;
                    }),
                    options: NewComplaintDialog._typeKeys
                        .map((k) => (value: k, label: context.tr(k)))
                        .toList(),
                    selectedValue: _selectedTypeKey,
                    onSelect: (v) => setState(() {
                      _selectedTypeKey = v;
                      _typeMenuOpen = false;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildPicker(
                    label: context.tr('complaint_related_order'),
                    isOpen: _orderMenuOpen,
                    enabled: !_loadingOrders && !_submitting,
                    selectedLabel: _loadingOrders
                        ? context.tr('loading')
                        : _orderPickerOptions
                            .firstWhere((o) => o.value == _selectedOrderKey)
                            .label,
                    onToggle: () => setState(() {
                      _typeMenuOpen = false;
                      _orderMenuOpen = !_orderMenuOpen;
                    }),
                    options: _orderPickerOptions,
                    selectedValue: _selectedOrderKey,
                    onSelect: (v) => setState(() {
                      _selectedOrderKey = v;
                      _orderMenuOpen = false;
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
