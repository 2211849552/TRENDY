import 'package:flutter/foundation.dart';

import '../locale/app_locale.dart';
import '../l10n/app_strings.dart';

import '../services/api/wallet_api.dart';
import '../models/auth_session.dart';

/// معاملات تُسجَّل عند شحن المحفظة أو الدفع منها.
class WalletTransaction {
  WalletTransaction({
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
  });

  final String title;
  final String date;
  final String time;
  final double amount;
}

class WalletManager extends ChangeNotifier {
  WalletManager._internal();
  static final WalletManager _instance = WalletManager._internal();
  factory WalletManager() => _instance;

  double _balance = 0;
  final List<WalletTransaction> _transactions = [];

  double get balance => _balance;

  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  static const double minTopUp = 10;
  static const double maxBalance = 10000;

  final WalletApi _walletApi = WalletApi();

  /// مزامنة الرصيد والمعاملات من API (للزبون المسجّل).
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      final balance = await _walletApi.fetchBalance();
      _balance = balance.balance;

      final logs = await _walletApi.fetchLogs();
      _transactions
        ..clear()
        ..addAll(
          logs.map(
            (e) => WalletTransaction(
              title: e.title,
              date: _formatDate(e.date),
              time: _formatTime(e.date),
              amount: e.amount,
            ),
          ),
        );
      notifyListeners();
    } catch (_) {
      // نُبقي البيانات المحلية عند فشل الشبكة.
    }
  }

  static String _formatNowDate() => _formatDate(DateTime.now());

  static String _formatDate(DateTime now) {
    final lang = AppLocale.instance.locale.languageCode;
    if (lang == 'ar') {
      const monthsAr = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      return '${now.day.toString().padLeft(2, '0')} ${monthsAr[now.month]} ${now.year}';
    }
    const monthsEn = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthsEn[now.month]} ${now.day}, ${now.year}';
  }

  static String _formatNowTime() => _formatTime(DateTime.now());

  static String _formatTime(DateTime now) {
    final lang = AppLocale.instance.locale.languageCode;
    if (lang == 'ar') {
      final hour24 = now.hour;
      final hour = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
      final suffix = hour24 < 12 ? 'ص' : 'م';
      return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $suffix';
    }
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// شحن عبر سداد. يُرجع رسالة خطأ أو null عند النجاح.
  String? addSadadTopUp({required String phone, required double amount}) {
    final lang = AppLocale.instance.locale.languageCode;
    if (amount < minTopUp) {
      return AppStrings.byLang(lang, 'min_topup_err');
    }
    if (_balance + amount > maxBalance) {
      return AppStrings.byLang(lang, 'max_balance_err');
    }
    final phoneLabel = phone.trim().isNotEmpty ? phone.trim() : '—';
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransaction(
        title: AppStrings.formatLang(lang, 'tx_sadad', params: {'phone': phoneLabel}),
        date: _formatNowDate(),
        time: _formatNowTime(),
        amount: amount,
      ),
    );
    notifyListeners();
    return null;
  }

  /// خصم لطلب مدفوع من المحفظة. false إن لم يكفِ الرصيد.
  bool payOrderFromWallet({required String orderId, required double amount}) {
    if (amount <= 0) return false;
    if (_balance < amount) return false;
    final lang = AppLocale.instance.locale.languageCode;
    _balance -= amount;
    _transactions.insert(
      0,
      WalletTransaction(
        title: AppStrings.formatLang(lang, 'tx_order', params: {'id': orderId}),
        date: _formatNowDate(),
        time: _formatNowTime(),
        amount: -amount,
      ),
    );
    notifyListeners();
    return true;
  }
}
