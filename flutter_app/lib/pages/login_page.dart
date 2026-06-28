import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeSlide = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) { AppTheme.showSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true); setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundDecoration(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FadeTransition(
                  opacity: _fadeSlide,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(_fadeSlide),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primary.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeSlide,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(_fadeSlide),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (ctx, v, _) => Transform.scale(
                          scale: v,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.08), AppTheme.primaryLight.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(
                                'https://res.cloudinary.com/db33m8gqe/image/upload/q_auto/f_auto/v1781682894/New_Project_elxu7s.png',
                                width: 120, height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 60, color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeSlide,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeSlide),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppStrings.get('welcome_back'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(AppStrings.get('sign_in_hint'), style: TextStyle(fontSize: 15, color: AppTheme.greyShade(context, 600))),
                    ]),
                  ),
                ),
                const SizedBox(height: 36),
                _buildField(0, TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(labelText: AppStrings.get('email'), prefixIcon: const Icon(Icons.email_rounded)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.trim().isEmpty ? AppStrings.get('enter_email') : null,
                )),
                const SizedBox(height: 16),
                _buildField(1, TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('password'),
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? AppStrings.get('enter_password') : null,
                )),
                const SizedBox(height: 36),
                _buildField(2, SizedBox(
                  width: double.infinity, height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(AppStrings.get('login'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
                _buildField(3, Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(AppStrings.get('dont_have_account'), style: const TextStyle(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, CustomRoute(page: const RegisterPage())),
                    child: Text(AppStrings.get('register'), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(int index, Widget child) {
    return FadeTransition(
      opacity: _animCtrl.drive(Tween(begin: 0.0, end: 1.0)),
      child: SlideTransition(
        position: _animCtrl.drive(Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: Interval(index * 0.15, 0.6 + index * 0.1, curve: Curves.easeOutCubic)))),
        child: child,
      ),
    );
  }
}
