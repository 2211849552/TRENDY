import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'locale/app_locale.dart';
import 'models/auth_session.dart';
import 'models/notification_manager.dart';
import 'models/ratings_manager.dart';
import 'services/api/profile_api.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.load();
  await NotificationManager().load();
  await RatingsManager().ensureLoaded();
  if (AuthSession.instance.isAuthenticated) {
    await _ensureCustomerProfileId();
    NotificationManager().syncFromApi();
  }
  // يبدأ Firebase في الخلفية — لا يؤخر ظهور شاشة الإقلاع.
  // ignore: unused_local_variable
  final _ = splashBootstrapFuture;
  runApp(const AppRoot());
}

Future<void> _ensureCustomerProfileId() async {
  final user = AuthSession.instance.user;
  if (user == null || user.customerProfileId != null) return;
  try {
    final profile = await ProfileApi().fetchProfile();
    if (profile.id != null) {
      await AuthSession.instance.updateUser(
        user.copyWith(customerProfileId: profile.id),
      );
    }
  } catch (_) {
    // اختياري — تُعاد المحاولة عند مزامنة التقييمات.
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.instance, AppThemeMode.instance]),
      builder: (context, _) {
        final locale = AppLocale.instance.locale;
        final isAr = locale.languageCode == 'ar';
        final isLight = AppThemeMode.instance.isLight;
        return MaterialApp(
          title: 'Trendy',
          debugShowCheckedModeBanner: false,
          theme: isLight ? AppTheme.light(isAr: isAr) : AppTheme.dark(isAr: isAr),
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
