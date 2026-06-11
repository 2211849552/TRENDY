import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../address_map_screen.dart';
import '../l10n/app_strings.dart';
import '../models/addresses_manager.dart';
import '../models/delivery_zone.dart';
import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';
import 'zone_picker_screen.dart';

class AddressEditSheet extends StatefulWidget {
  const AddressEditSheet({
    super.key,
    required this.address,
    required this.isNew,
  });

  final SavedAddress address;
  final bool isNew;

  /// يُعيد `true` عند الحفظ بنجاح، `false` عند الفشل، `null` عند الإغلاق بدون حفظ.
  static Future<bool?> show(
    BuildContext context, {
    required SavedAddress address,
    required bool isNew,
  }) {
    return showModalBottomSheet<bool?>(
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
  bool _saving = false;

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

  Future<void> _changeZone() async {
    final zone = await Navigator.push<DeliveryZone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZonePickerScreen(selectedZoneId: _draft.zoneId),
      ),
    );
    if (zone == null || !mounted) return;
    final zoneLabel = _formatZoneName(zone.name);
    setState(() {
      _draft = _draft.copyWith(
        zoneId: zone.id,
        city: zoneLabel,
        streetLine: zoneLabel,
      );
    });
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

  Future<void> _save() async {
    if (_saving) return;
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    setState(() => _saving = true);
    final updated = _draft.copyWith(
      label: label,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    final ok = await _manager.upsert(
      updated,
      selectAfter: widget.isNew || _manager.selectedId == updated.id,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _manager.error!.startsWith('addr_')
                ? context.tr(_manager.error!)
                : (_manager.error ?? context.tr('error_generic')),
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: t.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                    context.tr('delivery_zone'),
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_city_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _draft.city,
                            style: GoogleFonts.cairo(
                              color: t.titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _changeZone,
                          child: Text(
                            context.tr('change_zone'),
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
                  Text(
                    context.tr('addr_map_pin_optional'),
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
                            '${_draft.lat.toStringAsFixed(4)}, ${_draft.lng.toStringAsFixed(4)}',
                            style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : _changeLocation,
                          icon: Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
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
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: context.tr('addr_desc_optional'),
                    controller: _descCtrl,
                    enabled: !_saving,
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
                          onTap: _saving ? null : _save,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
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


  String _formatZoneName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
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
          enabled: enabled,
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
