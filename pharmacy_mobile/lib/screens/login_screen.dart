import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';

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
    return Scaffold(
      body: SafeArea(
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Huny Pharmacy',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text("Sign in to your shop's dashboard.", style: TextStyle(color: AppColors.inkSoft, fontSize: 16)),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEAEA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF3B4AE)),
                            ),
                            child: Text(_error!, style: const TextStyle(color: AppColors.bad, fontWeight: FontWeight.w600)),
                          ),
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'you@shop.com'),
                        ),
                        const SizedBox(height: 18),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(hintText: '••••••••'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                ),
                                const Text('Remember me', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                              },
                              child: const Text('Forgot password?', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            child: Text(_loading ? 'Signing in…' : 'Sign in'),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
                              children: [
                                const TextSpan(text: 'New shop or joining one? '),
                                TextSpan(
                                  text: 'Create an account',
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
    );
  }
}
