import 'api_client.dart';

/// استجابة رصيد المحفظة من API.
class WalletBalance {
  const WalletBalance({required this.balance, this.currency = 'LYD'});

  final double balance;
  final String currency;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : json;
    return WalletBalance(
      balance: _asDouble(map['balance']) ?? 0,
      currency: '${map['currency'] ?? 'LYD'}',
    );
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}

/// سجل حركة مالية في المحفظة.
class WalletLogEntry {
  const WalletLogEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  final int id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;

  factory WalletLogEntry.fromJson(Map<String, dynamic> json) {
    final txType = '${json['transaction_type'] ?? json['type'] ?? ''}';
    final isCredit = txType == 'deposit' || '${json['type']}' == 'credit';
    final rawAmount = WalletBalance._asDouble(json['amount']) ?? 0;

    return WalletLogEntry(
      id: int.tryParse('${json['transaction_id'] ?? json['id'] ?? ''}') ?? 0,
      title: '${json['description'] ?? txType}'.trim(),
      amount: isCredit ? rawAmount.abs() : -rawAmount.abs(),
      date: DateTime.tryParse('${json['date'] ?? json['created_at'] ?? ''}') ?? DateTime.now(),
      type: txType,
    );
  }
}

/// واجهة API المحفظة الإلكترونية للزبون.
class WalletApi {
  WalletApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /api/wallet/balance
  Future<WalletBalance> fetchBalance() async {
    final json = await _client.getFromRoot('/wallet/balance');
    return WalletBalance.fromJson(json);
  }

  /// GET /api/wallet/logs
  Future<List<WalletLogEntry>> fetchLogs({int perPage = 30}) async {
    final json = await _client.getFromRoot('/wallet/logs', query: {'per_page': '$perPage'});
    final rows = json['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(WalletLogEntry.fromJson)
        .where((e) => e.id > 0 || e.title.isNotEmpty)
        .toList();
  }

  /// POST /api/wallet/payment-method — إنشاء payment_method_id من بيانات البطاقة
  Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
  }) async {
    final json = await _client.postFromRoot(
      '/wallet/payment-method',
      body: {
        'card_number': cardNumber.replaceAll(RegExp(r'\s'), ''),
        'exp_month': expMonth,
        'exp_year': expYear,
        'cvc': cvc,
      },
    );
    final data = json['data'];
    if (data is Map && '${data['payment_method_id'] ?? ''}'.isNotEmpty) {
      return '${data['payment_method_id']}';
    }
    throw FormatException('${json['message'] ?? 'لم يُرجع الخادم معرف طريقة الدفع'}');
  }

  /// POST /api/wallet/top-up
  Future<double?> topUp({
    required double amount,
    required String paymentMethodId,
  }) async {
    final json = await _client.postFromRoot(
      '/wallet/top-up',
      body: {
        'amount': amount,
        'payment_method_id': paymentMethodId,
      },
    );
    final data = json['data'];
    if (data is Map) {
      return WalletBalance._asDouble(data['balance_after']);
    }
    return null;
  }
}
