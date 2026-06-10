import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';
import 'models/auth_session.dart';
import 'models/wallet_manager.dart';
import 'wallet_top_up_screen.dart';
import 'widgets/app_back_button.dart';
import 'widgets/trendy_brand.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletManager _wallet = WalletManager();

  @override
  void initState() {
    super.initState();
    if (AuthSession.instance.isAuthenticated) {
      _wallet.syncFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListenableBuilder(
            listenable: Listenable.merge([_wallet, AppLocale.instance]),
            builder: (context, _) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        context.tr('wallet_title'),
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBalanceCard(),
                          const SizedBox(height: 32),
                          Text(
                            context.tr('wallet_last_tx'),
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionsList(),
                          const SizedBox(height: 32),
                          _buildWalletInfo(),
                          const SizedBox(height: 40),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        AppBackLink(
          label: context.tr('back'),
          onPressed: () => Navigator.pop(context),
        ),
        // Trendy Logo
        const TrendyBrandBadge(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final balance = _wallet.balance;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF1C1A33)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
              ),
              // Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr('wallet_current'),
                    style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                  Text(
                    context.tr('wallet_active'),
                    style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Balance formatting
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance.toStringAsFixed(2),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('wallet_currency'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Recharge Button (سداد — pill أبيض كنموذج Figma)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: _openTopUpScreen,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Color(0xFFA855F7), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('wallet_topup'),
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFA855F7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final txs = _wallet.transactions;
    if (txs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          context.tr('wallet_empty_tx'),
          textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: txs.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
        itemBuilder: (context, index) {
          final tx = txs[index];
          final bool isNegative = tx.amount < 0;
          final String amountStr = '${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(2)}';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${tx.date} • ${tx.time}',
                        style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$amountStr${context.tr('currency_suffix')}',
                      style: GoogleFonts.cairo(
                        color: isNegative ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isNegative ? Colors.redAccent : Colors.greenAccent,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFA855F7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('wallet_info_title'),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildBullet(context.tr('wallet_info_1')),
          _buildBullet(context.tr('wallet_info_2')),
          _buildBullet(context.tr('wallet_info_3')),
          _buildBullet(context.tr('wallet_info_4')),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, color: const Color(0xFF3B82F6), size: 8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTopUpScreen() async {
    if (!AuthSession.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('wallet_login_required'), style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WalletTopUpScreen()),
    );
    if (ok == true && mounted) {
      await _wallet.syncFromApi();
    }
  }
}
