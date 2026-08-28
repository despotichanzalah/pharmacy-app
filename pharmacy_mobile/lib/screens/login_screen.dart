import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../i18n/app_lang.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ApiService.login(_emailController.text.trim(), _passwordController.text, _rememberMe);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLang.instance,
      builder: (context, _) => Scaffold(
        body: Stack(
          children: [
            // Soft decorative glow, purely visual — sits behind everything.
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.10)),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.07)),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 44),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('appName'),
                                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: -0.3)),
                                const Text("HUNY'S APP",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 1.1)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 14)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t('welcomeBack'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                              const SizedBox(height: 6),
                              Text(t('signInSub'), style: const TextStyle(color: AppColors.inkSoft, fontSize: 15)),
                              const SizedBox(height: 26),
                              if (_error != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(13),
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDEAEA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF3B4AE)),
                                  ),
                                  child: Text(_error!, style: const TextStyle(color: AppColors.bad, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              Text(t('email'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'you@shop.com',
                                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.inkSoft),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(t('password'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.inkSoft),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.inkSoft),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(t('rememberMe'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                    },
                                    child: Text(t('forgotPassword'), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(elevation: 6, shadowColor: AppColors.primary.withOpacity(0.4)),
                                  onPressed: _loading ? null : _handleLogin,
                                  child: Text(_loading ? t('signingIn') : t('signIn'), style: const TextStyle(fontSize: 15)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
                                    children: [
                                      TextSpan(text: '${t('newShopQuestion')} '),
                                      TextSpan(
                                        text: t('createAccount'),
                                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                                        recognizer: (TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                                          }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
