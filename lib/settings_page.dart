import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/notification_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'complaints_screen.dart';
import 'wallet_screen.dart';
import 'models/wallet_manager.dart';
import 'locale/app_locale.dart';
import 'l10n/app_strings.dart';
import 'login_screen.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const SettingsPage({super.key, required this.onBrowseStores});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = NotificationManager().isEnabled;

  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phoneField;
  late final TextEditingController _address;
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;

  final WalletManager _wallet = WalletManager();

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController();
    _email = TextEditingController();
    _phoneField = TextEditingController();
    _address = TextEditingController();
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phoneField.dispose();
    _address.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('saved_ok'), style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF1E5BB3),
      ),
    );
  }

  void _changePassword() {
    final cur = _currentPassword.text;
    final newP = _newPassword.text;
    final conf = _confirmPassword.text;
    if (cur.isEmpty || newP.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pwd_fill_all'), style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    if (newP != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pwd_mismatch'), style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    if (newP.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pwd_short'), style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('pwd_changed_ok'), style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF1E5BB3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1931),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListenableBuilder(
        listenable: Listenable.merge([_wallet, AppLocale.instance]),
        builder: (context, _) {
          return Directionality(
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 20),
              // Header Match OrdersPage / FavoritesPage
              _buildHeader(),
              const SizedBox(height: 32),

              // Title aligned like other pages
              Text(
                context.tr('settings_title'),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Links Section
              _buildSectionCard(
                title: context.tr('settings_quick_links'),
                subtitle: context.tr('settings_quick_links_sub'),
                children: [
                  _buildQuickLink(
                    title: context.tr('wallet'),
                    subtitle: AppStrings.format(context, 'wallet_link_sub', params: {
                      'balance': _wallet.balance.toStringAsFixed(2),
                    }),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const WalletScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickLink(
                    title: context.tr('notifications'),
                    subtitle: AppStrings.format(context, 'notifications_unread', params: {
                      'count': NotificationManager().unreadCount.toString(),
                    }),
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  _buildQuickLink(
                    title: context.tr('support'),
                    subtitle: context.tr('support_sub'),
                    icon: Icons.support_agent_outlined,
                    showBorder: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Personal Info Section
              _buildSectionCard(
                title: context.tr('personal_info'),
                subtitle: context.tr('personal_info_sub'),
                icon: Icons.person_outline,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          context.tr('full_name'),
                          hint: context.tr('hint_name'),
                          controller: _fullName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          context.tr('email'),
                          hint: context.tr('hint_email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          context.tr('phone'),
                          hint: context.tr('hint_phone'),
                          controller: _phoneField,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          context.tr('address'),
                          hint: context.tr('hint_address'),
                          controller: _address,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(context.tr('save_changes'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Change Password Section
              _buildSectionCard(
                title: context.tr('change_password_title'),
                subtitle: context.tr('change_password_sub'),
                icon: Icons.lock_outline,
                children: [
                  _buildInputField(
                    context.tr('current_password'),
                    hint: context.tr('hint_password'),
                    controller: _currentPassword,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          context.tr('new_password'),
                          hint: context.tr('hint_password'),
                          controller: _newPassword,
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          context.tr('confirm_password'),
                          hint: context.tr('hint_password'),
                          controller: _confirmPassword,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(context.tr('change_password_btn'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App Preferences Section
              _buildSectionCard(
                title: context.tr('app_prefs'),
                subtitle: context.tr('app_prefs_sub'),
                icon: Icons.settings_outlined,
                children: [
                  // Notifications Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('enable_notifications'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(context.tr('notifications_desc'), style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (val) {
                          setState(() => _notificationsEnabled = val);
                          NotificationManager().setEnabled(val); // This actually disables incoming notifications
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val ? context.tr('notifications_enabled') : context.tr('notifications_disabled'),
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: val ? const Color(0xFF1E5BB3) : Colors.grey.shade800,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        activeColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10),
                  ),
                  // Language Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('language'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(context.tr('language_desc'), style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Locale>(
                            value: AppLocale.instance.locale,
                            dropdownColor: const Color(0xFF121E36),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: const Locale('ar'),
                                child: Text(context.tr('lang_ar'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                              DropdownMenuItem(
                                value: const Locale('en'),
                                child: Text(context.tr('lang_en'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ],
                            onChanged: (loc) {
                              if (loc != null) AppLocale.instance.setLocale(loc);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Logout Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('logout'), style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(context.tr('logout_desc'), style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E5BB3),
                          title: Text(context.tr('logout_confirm_title'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text(context.tr('logout_confirm_desc'), style: GoogleFonts.cairo(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.tr('cancel'), style: GoogleFonts.cairo(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: Text(context.tr('logout'), style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
                    label: Text(context.tr('logout_btn'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBrowseStores,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5BB3).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trendy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(width: 6),
              Icon(Icons.checkroom_rounded, color: Colors.blueAccent, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuickLink({
    required String title,
    required String subtitle,
    required IconData icon,
    bool showBorder = true,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: Colors.white10)) : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 24),
        ),
        title: Text(title, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }
}
