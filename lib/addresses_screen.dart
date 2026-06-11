import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';
import 'models/addresses_manager.dart';
import 'models/delivery_zone.dart';
import 'theme/app_colors.dart';
import 'theme/trendy_theme_extension.dart';
import 'widgets/address_edit_sheet.dart';
import 'widgets/app_back_button.dart';
import 'widgets/zone_picker_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AddressesManager _manager = AddressesManager();

  @override
  void initState() {
    super.initState();
    _manager.syncFromApi();
  }

  void _showError(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    final text = message.startsWith('addr_') ? context.tr(message) : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: GoogleFonts.cairo())),
    );
  }

  Future<void> _openNewAddress() async {
    final zone = await Navigator.push<DeliveryZone>(
      context,
      MaterialPageRoute(builder: (_) => const ZonePickerScreen()),
    );
    if (zone == null || !mounted) return;

    final zoneLabel = _formatZoneName(zone.name);
    final draft = SavedAddress(
      id: _manager.nextId(),
      label: '',
      streetLine: zoneLabel,
      city: zoneLabel,
      zoneId: zone.id,
      lat: AddressesManager.defaultLat,
      lng: AddressesManager.defaultLng,
    );

    final ok = await AddressEditSheet.show(context, address: draft, isNew: true);
    if (!mounted) return;
    if (ok == false) _showError(_manager.error);
    setState(() {});
  }

  String _formatZoneName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _confirmDelete(SavedAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.trendy.surfaceColor,
        title: Text(context.tr('addr_delete'), style: GoogleFonts.cairo(color: context.trendy.titleColor)),
        content: Text(
          context.tr('delete_address_confirm'),
          style: GoogleFonts.cairo(color: context.trendy.subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel'), style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('addr_delete'), style: GoogleFonts.cairo(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final removed = await _manager.remove(address.id);
      if (!mounted) return;
      if (!removed) _showError(_manager.error);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;

    return Scaffold(
      backgroundColor: t.pageBackground,
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListenableBuilder(
            listenable: Listenable.merge([_manager, AppLocale.instance]),
            builder: (context, _) {
              final list = _manager.addresses;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        AppBackIconButton(onPressed: () => Navigator.pop(context)),
                        const Spacer(),
                        Text(
                          context.tr('my_addresses'),
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: t.titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_manager.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_manager.error != null && list.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _manager.error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(color: t.subtitleColor),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _manager.syncFromApi,
                                child: Text(context.tr('retry'), style: GoogleFonts.cairo()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          context.tr('no_addresses'),
                          style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final address = list[index];
                          final selected = _manager.selectedId == address.id;
                          return _AddressCard(
                            address: address,
                            selected: selected,
                            onSelect: () => _manager.select(address.id),
                            onDelete: () => _confirmDelete(address),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _manager.isLoading ? null : _openNewAddress,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('new_address'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final SavedAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: t.cardFill.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : t.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _SelectionDot(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  address.label,
                  style: GoogleFonts.cairo(
                    color: t.titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                tooltip: context.tr('addr_delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.trendy.hintColor, width: 2),
      ),
    );
  }
}
