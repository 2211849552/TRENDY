import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'complaints_screen.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const SettingsPage({super.key, required this.onBrowseStores});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  String selectedLanguage = 'العربية';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1931),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
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
                'الإعدادات',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Links Section
              _buildSectionCard(
                title: 'روابط سريعة',
                subtitle: 'الوصول السريع للصفحات المهمة',
                children: [
                  _buildQuickLink(
                    title: 'المحفظة',
                    subtitle: '100.00 د.ل',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _buildQuickLink(
                    title: 'الإشعارات',
                    subtitle: '0 غير مقروء',
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  _buildQuickLink(
                    title: 'الشكاوى والدعم',
                    subtitle: '0 شكوى',
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
                title: 'المعلومات الشخصية',
                subtitle: 'قم بتحديث بياناتك الشخصية',
                icon: Icons.person_outline,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildInputField('الاسم الكامل', 'aya adel')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField('البريد الإلكتروني', 'kaissomar@gmail.com')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField('رقم الهاتف', '+218 91 234 5678')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField('العنوان', 'المدينة، الشارع')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('حفظ التغييرات', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Change Password Section
              _buildSectionCard(
                title: 'تغيير كلمة المرور',
                subtitle: 'قم بتحديث كلمة المرور الخاصة بك',
                icon: Icons.lock_outline,
                children: [
                  _buildInputField('كلمة المرور الحالية', '********', obscureText: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField('كلمة المرور الجديدة', '********', obscureText: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField('تأكيد كلمة المرور', '********', obscureText: true)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('تغيير كلمة المرور', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App Preferences Section
              _buildSectionCard(
                title: 'تفضيلات التطبيق',
                subtitle: 'إدارة إعدادات التطبيق',
                icon: Icons.settings_outlined,
                children: [
                  // Notifications Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تفعيل الإشعارات', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('استلام إشعارات حول الطلبات والعروض الخاصة', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: notificationsEnabled,
                        onChanged: (val) => setState(() => notificationsEnabled = val),
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
                            Text('اللغة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('اختر اللغة المفضلة لواجهة التطبيق', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedLanguage,
                            dropdownColor: const Color(0xFF121E36),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                            isExpanded: true,
                            items: ['العربية', 'English']
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedLanguage = val);
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
                      Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('إنهاء جلسة العمل الحالية والخروج من الحساب', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handled in main navigation or state
                    },
                    icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
                    label: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: widget.onBrowseStores,
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          label: const Text(
            'رجوع',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5BB3).withValues(alpha: 0.3),
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
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
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
            color: Colors.blueAccent.withValues(alpha: 0.1),
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

  Widget _buildInputField(String label, String hint, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
