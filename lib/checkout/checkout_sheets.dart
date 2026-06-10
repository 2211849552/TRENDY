import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../locale/app_locale.dart';
import '../models/addresses_manager.dart';
import '../models/wallet_manager.dart';
import '../theme/app_colors.dart';
import '../theme/trendy_theme_extension.dart';
import '../wallet_screen.dart';
import '../widgets/address_edit_sheet.dart';
import '../widgets/gradient_button.dart';

/// اختيار عنوان التوصيل من قائمة العناوين المحفوظة.
Future<void> showAddressPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddressPickerSheet(),
  );
}

/// اختيار طريقة الدفع (نقداً / محفظة) مع زر تأكيد.
Future<String?> showPaymentPickerSheet(
  BuildContext context, {
  String? initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PaymentPickerSheet(initial: initial),
  );
}

class _AddressPickerSheet extends StatefulWidget {
  const _AddressPickerSheet();

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  final AddressesManager _manager = AddressesManager();

  @override
  void initState() {
    super.initState();
    _manager.syncFromApi();
  }

  Future<void> _openEdit(SavedAddress address) async {
    await AddressEditSheet.show(context, address: address, isNew: false);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(SavedAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.trendy.surfaceColor,
        title: Text(
          context.tr('addr_delete'),
          style: GoogleFonts.cairo(color: context.trendy.titleColor),
        ),
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
            child: Text(
              context.tr('addr_delete'),
              style: GoogleFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _manager.remove(address.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;

    return ListenableBuilder(
      listenable: Listenable.merge([_manager, AppLocale.instance]),
      builder: (context, _) {
        final list = _manager.addresses;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: t.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  context.tr('select_your_address'),
                  style: GoogleFonts.cairo(
                    color: t.titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final address = list[index];
                    final selected = _manager.selectedId == address.id;
                    return _SheetAddressRow(
                      address: address,
                      selected: selected,
                      onSelect: () {
                        _manager.select(address.id);
                        Navigator.pop(context);
                      },
                      onEdit: () => _openEdit(address),
                      onDelete: () => _confirmDelete(address),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetAddressRow extends StatelessWidget {
  const _SheetAddressRow({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address.label,
                  style: GoogleFonts.cairo(
                    color: t.titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: t.titleColor, size: 20),
                tooltip: context.tr('edit'),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                tooltip: context.tr('addr_delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentPickerSheet extends StatefulWidget {
  const _PaymentPickerSheet({this.initial});

  final String? initial;

  @override
  State<_PaymentPickerSheet> createState() => _PaymentPickerSheetState();
}

class _PaymentPickerSheetState extends State<_PaymentPickerSheet> {
  late String? _selected = widget.initial;
  final WalletManager _wallet = WalletManager();

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;
    final balance = _wallet.balance;

    return ListenableBuilder(
      listenable: Listenable.merge([_wallet, AppLocale.instance]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: t.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('select_payment_method'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: t.titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _PaymentOption(
                selected: _selected == 'payment_cash',
                onTap: () => setState(() => _selected = 'payment_cash'),
                icon: Icons.payments_outlined,
                iconColor: Colors.greenAccent,
                title: context.tr('payment_cash'),
              ),
              const SizedBox(height: 12),
              _PaymentOption(
                selected: _selected == 'payment_wallet',
                onTap: () => setState(() => _selected = 'payment_wallet'),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.orangeAccent,
                title: context.tr('payment_wallet'),
                subtitle:
                    '${balance.toStringAsFixed(0)}${context.tr('currency_suffix')}',
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    context.tr('wallet_recharge_short'),
                    style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(context, _selected),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      context.tr('confirm_action'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.trendy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              const Spacer(),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    subtitle!,
                    style: GoogleFonts.cairo(
                      color: t.subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: t.titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: iconColor, size: 24),
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
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.trendy.hintColor, width: 2),
      ),
    );
  }
}
