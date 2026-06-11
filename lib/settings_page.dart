import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/notification_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'addresses_screen.dart';
import 'complaints_screen.dart';
import 'wallet_screen.dart';
import 'models/wallet_manager.dart';
import 'locale/app_locale.dart';
import 'theme/app_theme_mode.dart';
import 'theme/app_colors.dart';
import 'theme/trendy_theme_extension.dart';
import 'l10n/app_strings.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'widgets/app_back_button.dart';
import 'widgets/gradient_button.dart';
import 'widgets/trendy_brand.dart';
import 'models/auth_session.dart';
import 'models/customer_profile.dart';
import 'services/api/api_exception.dart';
import 'services/api/auth_api.dart';
import 'services/api/profile_api.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const SettingsPage({super.key, required this.onBrowseStores});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  final NotificationManager _notifManager = NotificationManager();
  final CustomerProfileStore _profileStore = CustomerProfileStore();
  final AuthApi _authApi = AuthApi();
  final ProfileApi _profileApi = ProfileApi();
  bool _isLoggingOut = false;
  bool _isSavingProfile = false;
  bool _isLoadingProfile = false;

  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phoneField;
  late final TextEditingController _address;

  final WalletManager _wallet = WalletManager();

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController();
    _email = TextEditingController();
    _phoneField = TextEditingController();
    _address = TextEditingController();

    _applyProfileToFields(_profileStore.current);
    _loadProfileFromApi();
  }

  void _applyProfileToFields(CustomerProfile? p) {
    if (p == null) return;
    _fullName.text = p.name;
    _email.text = p.email;
    _phoneField.text = p.phone;
    _address.text = p.address ?? '';
  }

  Future<void> _loadProfileFromApi() async {
    if (!AuthSession.instance.isAuthenticated) return;
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _profileApi.fetchProfile();
      if (!mounted) return;
      final user = profile.toAuthUser(id: AuthSession.instance.user?.id);
      await AuthSession.instance.updateUser(user);
      _applyProfileToFields(_profileStore.current);
    } catch (_) {
      // نُبقي البيانات المحلية إن فشل التحميل.
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phoneField.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    if (!AuthSession.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('wallet_login_required'), style: GoogleFonts.cairo()),
        ),
      );
      return;
    }

    final name = _fullName.text.trim();
    final email = _email.text.trim();
    final phone = _phoneField.text.trim();
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile_fields_required'), style: GoogleFonts.cairo()),
        ),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final updated = await _profileApi.updateProfile(
        name: name,
        email: email,
        phone: phone,
        defaultAddress: _address.text.trim(),
      );
      final user = updated.toAuthUser(id: AuthSession.instance.user?.id);
      await AuthSession.instance.updateUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('saved_ok'), style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFFA855F7),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.cairo())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile_save_failed'), style: GoogleFonts.cairo()),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.trendy.pageBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListenableBuilder(
        listenable: Listenable.merge([_wallet, _notifManager, AppLocale.instance, AppThemeMode.instance]),
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
                  color: context.trendy.titleColor,
                ),
              ),
              const SizedBox(height: 24),

              // Customer Profile (read-only display)
              ListenableBuilder(
                listenable: _profileStore,
                builder: (context, _) {
                  final p = _profileStore.current;
                  final name = (p?.name.trim().isNotEmpty ?? false) ? p!.name : '—';
                  final email = (p?.email.trim().isNotEmpty ?? false) ? p!.email : '—';
                  final phone = (p?.phone.trim().isNotEmpty ?? false) ? p!.phone : '—';
                  return _buildSectionCard(
                    title: context.tr('personal_info'),
                    subtitle: context.tr('personal_info_sub'),
                    icon: Icons.person_outline,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _profileRow(icon: Icons.person_outline, label: context.tr('full_name'), value: name),
                            const SizedBox(height: 10),
                            _profileRow(icon: Icons.email_outlined, label: context.tr('email'), value: email),
                            const SizedBox(height: 10),
                            _profileRow(icon: Icons.phone_outlined, label: context.tr('phone'), value: phone),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                    title: context.tr('my_addresses'),
                    subtitle: context.tr('my_addresses_sub'),
                    icon: Icons.location_on_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AddressesScreen(),
                        ),
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
                    child: GradientButton(
                      onPressed: (_isSavingProfile || _isLoadingProfile) ? null : _saveProfile,
                      label: _isSavingProfile
                          ? context.tr('auth_loading')
                          : context.tr('save_changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Change Password Section — api.md: استعادة عبر forgot/verify/reset
              _buildSectionCard(
                title: context.tr('change_password_title'),
                subtitle: context.tr('change_password_sub_api'),
                icon: Icons.lock_outline,
                children: [
                  Text(
                    context.tr('change_password_via_reset'),
                    style: GoogleFonts.cairo(
                      color: context.trendy.subtitleColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GradientButton(
                      onPressed: _changePassword,
                      label: context.tr('forgot_pwd_title'),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('enable_notifications'),
                              style: GoogleFonts.cairo(
                                color: context.trendy.titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('notifications_desc'),
                              style: GoogleFonts.cairo(
                                color: context.trendy.subtitleColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _notifManager.notificationsEnabled,
                        onChanged: _notifManager.isUpdatingPreference
                            ? null
                            : (val) async {
                                final ok = await _notifManager.setNotificationsEnabled(val);
                                if (!context.mounted) return;
                                if (!ok && _notifManager.preferenceError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _notifManager.preferenceError!,
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: context.trendy.dividerColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('light_mode'),
                              style: GoogleFonts.cairo(
                                color: context.trendy.titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.tr('light_mode_desc'),
                              style: GoogleFonts.cairo(color: context.trendy.subtitleColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: AppThemeMode.instance.isLight,
                        onChanged: AppThemeMode.instance.setLightMode,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: context.trendy.dividerColor),
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
                            Text(context.tr('language'), style: GoogleFonts.cairo(color: context.trendy.titleColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(context.tr('language_desc'), style: GoogleFonts.cairo(color: context.trendy.subtitleColor, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.trendy.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.trendy.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Locale>(
                            value: AppLocale.instance.locale,
                            dropdownColor: context.trendy.surfaceColor,
                            icon: Icon(Icons.keyboard_arrow_down, color: context.trendy.subtitleColor),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: const Locale('ar'),
                                child: Text(context.tr('lang_ar'), style: TextStyle(color: context.trendy.titleColor, fontSize: 14)),
                              ),
                              DropdownMenuItem(
                                value: const Locale('en'),
                                child: Text(context.tr('lang_en'), style: TextStyle(color: context.trendy.titleColor, fontSize: 14)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('logout'),
                    style: GoogleFonts.cairo(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('logout_desc'),
                    style: GoogleFonts.cairo(
                      color: context.trendy.subtitleColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1B4B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(context.tr('logout'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text(context.tr('logout_desc'), style: GoogleFonts.cairo(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(context.tr('cancel'), style: GoogleFonts.cairo(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: _isLoggingOut
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      Navigator.pop(ctx);
                                      setState(() => _isLoggingOut = true);
                                      try {
                                        await _authApi.logout();
                                      } finally {
                                        if (mounted) setState(() => _isLoggingOut = false);
                                      }
                                      if (!mounted) return;
                                      navigator.pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    },
                              child: Text(context.tr('logout_btn'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
                    label: Text(context.tr('logout_btn'), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
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
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
          child: AppBackIconButton(
            onPressed: widget.onBrowseStores,
          ),
        ),
        const TrendyBrandBadge(),
      ],
    );
  }

  Widget _profileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final t = context.trendy;
    return Row(
      children: [
        Icon(icon, color: t.subtitleColor, size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(color: t.titleColor, fontSize: 13, fontWeight: FontWeight.bold),
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
    final t = context.trendy;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.cardBorder),
        boxShadow: AppThemeMode.instance.isLight
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: t.titleColor, size: 24),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(color: t.titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13)),
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
    final t = context.trendy;
    return Container(
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: t.dividerColor)) : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: GoogleFonts.cairo(color: t.titleColor, fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(color: t.subtitleColor, fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: t.hintColor, size: 16),
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
    final t = context.trendy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: t.titleColor, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: t.titleColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.hintColor, fontSize: 14),
            filled: true,
            fillColor: t.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
