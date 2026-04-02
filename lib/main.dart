import 'package:flutter/material.dart';

void main() {
  runApp(const TrendyApp());
}

class TrendyApp extends StatelessWidget {
  const TrendyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trendy',
      // إخفاء شريط الـ debug
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0061FF)),
        useMaterial3: true,
        fontFamily: 'Cairo', // يمكنك استخدام خط مثل Cairo إذا كان متوفراً
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // لون الخلفية الأزرق كما في الصورة
      backgroundColor: const Color(0xFF0061FF), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // دائرة الشعار البيضاء
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  // أيقونة الملابس (يمكنك استبدالها بصورة asset مثل Image.asset('assets/tshirt.png') لاحقاً)
                  Icon(
                    Icons.checkroom, 
                    size: 80,
                    color: Color(0xFF0061FF),
                  ),
                  // النجمة الصغيرة (الشرارة/sparkle)
                  Positioned(
                    top: 25,
                    right: 25,
                    child: Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber, 
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // اسم التطبيق Trendy
            const Text(
              'Trendy',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // الشعار الوصفي (Slogan)
            const Text(
              'الموضة في متناول يدك',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // النقاط الثلاث السفلية
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(),
                const SizedBox(width: 10),
                _buildDot(),
                const SizedBox(width: 10),
                _buildDot(),
              ],
            )
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء النقطة البيضاء
  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
    );
  }
}
