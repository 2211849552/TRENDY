import 'package:flutter/material.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  int _selectedIndex = 4; // Assuming "Settings" or "Complaints" is at the end, but let's keep it 4 for now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931), // Matching Home Screen dark blue
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Custom Header
                _buildHeader(context),
                const SizedBox(height: 30),
                // Title
                const Text(
                  'الشكاوي والدعم',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // New Complaint Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text(
                      'شكوى جديدة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6), // Bright Blue
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Empty State Card
                _buildEmptyState(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Trendy Logo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5BB3).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Text(
                'Trendy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.checkroom_rounded, color: Colors.blueAccent, size: 20),
            ],
          ),
        ),
        // Back Button
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            children: [
              Text(
                'رجوع',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.feedback_outlined,
              size: 60,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد شكاوى',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك انشاء شكوى جديدة من الزر أعلاه',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        if (index == 0) Navigator.pop(context); // Go back to home
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0A1931),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'المتجر'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'المفضلة'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined), activeIcon: Icon(Icons.shopping_basket), label: 'السلة'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'الإعدادات'),
      ],
    );
  }
}
