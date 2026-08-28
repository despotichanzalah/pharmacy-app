import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'i18n/app_lang.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const PharmacyApp());
}

// Same color identity as the web app (orange primary, warm neutral background).
class AppColors {
  static const primary = Color(0xFFF4A261);
  static const primaryDark = Color(0xFFE98F4A);
  static const primaryLight = Color(0xFFFFF4EE);
  static const ink = Color(0xFF374151);
  static const inkSoft = Color(0xFF6B7280);
  static const surface = Color(0xFFF8F7F5);
  static const line = Color(0xFFE5E7EB);
  static const bad = Color(0xFFE05252);
  static const good = Color(0xFF22A06B);
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app (and flips text direction) whenever the language toggles.
    return AnimatedBuilder(
      animation: AppLang.instance,
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.instance.isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp(
            title: 'Pharmacy System',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
          ),
        );
      },
    );
  }
}

// Decides whether to show Login or Dashboard based on whether a token is saved.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasToken = snapshot.data != null;
        return hasToken ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}
