import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../locale/app_locale.dart';
import '../models/auth_session.dart';
import '../models/wallet_manager.dart';
import '../services/api/api_exception.dart';
import '../services/api/wallet_api.dart';
import '../widgets/app_back_button.dart';

/// شاشة شحن المحفظة عبر بطاقة (Stripe) — تطابق واجهة الاشتراك/الشحن.
class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final WalletApi _walletApi = WalletApi();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  final _amount = TextEditingController(text: '100.00');

  bool _loading = false;
  double _balance = WalletManager().balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      final b = await _walletApi.fetchBalance();
      if (mounted) setState(() => _balance = b.balance);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _cvc.dispose();
    _amount.dispose();
    super.dispose();
  }

  (int month, int year)? _parseExpiry() {
    final parts = _expiry.text.split('/');
    if (parts.length != 2) return null;
    final month = int.tryParse(parts[0].trim());
    var year = int.tryParse(parts[1].trim());
    if (month == null || year == null || month < 1 || month > 12) return null;
    if (year < 100) year += 2000;
    return (month, year);
  }

  Future<void> _submit() async {
    if (!AuthSession.instance.isAuthenticated) {
      _showError(context.tr('wallet_login_required'));
      return;
    }

    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount < WalletManager.minTopUp) {
      _showError(context.tr('wallet_topup_amount_err'));
      return;
    }

    final expiry = _parseExpiry();
    if (expiry == null) {
      _showError(context.tr('wallet_card_expiry_err'));
      return;
    }

    final cardDigits = _cardNumber.text.replaceAll(RegExp(r'\s'), '');
    if (cardDigits.length < 13) {
      _showError(context.tr('wallet_card_number_err'));
      return;
    }

    final cvc = _cvc.text.trim();
    if (cvc.length < 3) {
      _showError(context.tr('wallet_card_cvc_err'));
      return;
    }

    setState(() => _loading = true);
    try {
      final paymentMethodId = await _walletApi.createPaymentMethod(
        cardNumber: cardDigits,
        expMonth: expiry.$1,
        expYear: expiry.$2,
        cvc: cvc,
      );

      await _walletApi.topUp(amount: amount, paymentMethodId: paymentMethodId);
      await WalletManager().syncFromApi();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('wallet_topup_success'), style: GoogleFonts.cairo()),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: Colors.redAccent.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListenableBuilder(
            listenable: AppLocale.instance,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: AppBackLink(
                    label: context.tr('back'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr('wallet_topup_screen_title'),
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildBalanceBox(),
                        const SizedBox(height: 16),
                        _buildInfoBanner(),
                        const SizedBox(height: 24),
                        _buildCardSection(),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 28),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wallet_current'),
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${_balance.toStringAsFixed(2)} ${context.tr('wallet_currency')}',
            style: GoogleFonts.cairo(
              color: const Color(0xFF4ADE80),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.35)),
      ),
      child: Text(
        context.tr('wallet_topup_info').replaceAll(
          '{balance}',
          '${_balance.toStringAsFixed(2)} ${context.tr('wallet_currency')}',
        ),
        style: GoogleFonts.cairo(color: const Color(0xFF86EFAC), fontSize: 13, height: 1.45),
      ),
    );
  }

  Widget _buildCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.credit_card, color: Color(0xFF3B82F6), size: 22),
            const SizedBox(width: 8),
            Text(
              context.tr('wallet_card_details'),
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _whiteField(
          controller: _cardNumber,
          label: context.tr('wallet_card_number'),
          hint: '1234 1234 1234 1234',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _whiteField(
                controller: _expiry,
                label: context.tr('wallet_card_expiry'),
                hint: context.tr('wallet_card_expiry_hint'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
                helper: context.tr('wallet_card_expiry_example'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _whiteField(
                controller: _cvc,
                label: context.tr('wallet_card_cvc'),
                hint: 'CVC',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                helper: context.tr('wallet_card_cvc_hint'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.45), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('wallet_stripe_note'),
                style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('wallet_topup_amount_label'),
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1C1A33),
            hintText: '100.00',
            hintStyle: GoogleFonts.cairo(color: Colors.white38),
            suffixText: context.tr('wallet_currency'),
            suffixStyle: GoogleFonts.cairo(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  context.tr('wallet_topup_btn'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _whiteField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helper,
    bool obscureText = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          maxLength: maxLength,
          style: GoogleFonts.cairo(color: Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: Colors.black38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper, style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11)),
        ],
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    var out = digits.length >= 2 ? '${digits.substring(0, 2)}/' : digits;
    if (digits.length > 2) {
      out += digits.substring(2, digits.length.clamp(2, 4));
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
