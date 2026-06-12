import 'package:shared_preferences/shared_preferences.dart';

/// بريدات سجّل الدخول/التسجيل بها سابقاً — للاختيار السريع.
class SavedEmailsStore {
  SavedEmailsStore._();

  static final SavedEmailsStore instance = SavedEmailsStore._();

  static const _key = 'saved_login_emails';
  static const _maxCount = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return const [];
    return raw.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> remember(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = [normalized, ...current.where((e) => e != normalized)];
    if (updated.length > _maxCount) {
      updated.removeRange(_maxCount, updated.length);
    }
    await prefs.setStringList(_key, updated);
  }

  Future<void> remove(String email) async {
    final normalized = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final updated = (await load()).where((e) => e != normalized).toList();
    await prefs.setStringList(_key, updated);
  }
}
