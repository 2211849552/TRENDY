import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../address_map_screen.dart';
import '../l10n/app_strings.dart';
import '../models/addresses_manager.dart';
import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';

class AddressEditSheet extends StatefulWidget {
  const AddressEditSheet({
    super.key,
    required this.address,
    required this.isNew,
  });

  final SavedAddress address;
  final bool isNew;

  static Future<void> show(
    BuildContext context, {
    required SavedAddress address,
    required bool isNew,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressEditSheet(address: address, isNew: isNew),
    );
  }

  @override
  State<AddressEditSheet> createState() => _AddressEditSheetState();
}

class _AddressEditSheetState extends State<AddressEditSheet> {
  late SavedAddress _draft;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _descCtrl;
  final AddressesManager _manager = AddressesManager();

  @override
  void initState() {
    super.initState();
    _draft = widget.address;
    _labelCtrl = TextEditingController(text: _draft.label);
    _descCtrl = TextEditingController(text: _draft.description ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push<SavedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressMapScreen(initial: _draft),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        streetLine: result.streetLine,
        city: result.city,
        lat: result.lat,
        lng: result.lng,
      );
    });
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;
    final updated = _draft.copyWith(
      label: label,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    _manager.upsert(updated, selectAfter: widget.isNew || _manager.selectedId == updated.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: t.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('addr_extra_title'),
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: t.titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('addr_extra_sub'),
                    style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('your_location'),
                    style: GoogleFonts.cairo(
                      color: t.subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _draft.streetLine,
                            style: GoogleFonts.cairo(color: t.titleColor, fontSize: 15),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _changeLocation,
                          icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          label: Text(
                            context.tr('change_location'),
                            style: GoogleFonts.cairo(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: context.tr('addr_name_label'),
                    controller: _labelCtrl,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: context.tr('addr_desc_optional'),
                    controller: _descCtrl,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _save,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              widget.isNew
                                  ? context.tr('save_address')
                                  : context.tr('update_address'),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _field({
    required String label,
    required TextEditingController controller,
  }) {
    final t = context.trendy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: t.subtitleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.cairo(color: t.titleColor, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
