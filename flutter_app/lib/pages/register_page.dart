import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../main_shell.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passCtrl.text;
    if (p.length < 6) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#$%^&*]'))) s++;
    return s;
  }

  Color get _strengthColor => switch (_passwordStrength) {
    0 => AppTheme.danger,
    1 => AppTheme.warning,
    2 => AppTheme.accent,
    _ => AppTheme.success,
  };

  String get _strengthLabel => switch (_passwordStrength) {
    0 => 'Weak',
    1 => 'Fair',
    2 => 'Good',
    _ => 'Strong',
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(),
        _phoneCtrl.text.trim(), _passCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
        setState(() => _loading = false);
      }
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
                _fadeSlide(0, GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primary.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
                  ),
                )),
                const SizedBox(height: 20),
                _fadeSlide(1, Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (ctx, v, _) => Transform.scale(
                      scale: v,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.08), AppTheme.primaryLight.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            'https://res.cloudinary.com/db33m8gqe/image/upload/q_auto/f_auto/v1781682894/New_Project_elxu7s.png',
                            width: 80, height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 50, color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                _fadeSlide(2, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppStrings.get('create_account'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(AppStrings.get('register_hint'), style: TextStyle(fontSize: 15, color: AppTheme.greyShade(context, 600))),
                ])),
                const SizedBox(height: 28),
                _fadeSlide(2, _sectionHeader(Icons.business_rounded, 'Institution Details')),
                const SizedBox(height: 12),
                _fadeSlide(3, TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: AppStrings.get('institution_name'), prefixIcon: const Icon(Icons.business_rounded)),
                  validator: (v) => v == null || v.trim().isEmpty ? AppStrings.get('enter_name') : null,
                  textCapitalization: TextCapitalization.words,
                )),
                const SizedBox(height: 12),
                _fadeSlide(3, TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(labelText: AppStrings.get('email'), prefixIcon: const Icon(Icons.email_rounded)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return AppStrings.get('enter_email');
                    if (!v.contains('@')) return AppStrings.get('valid_email');
                    return null;
                  },
                )),
                const SizedBox(height: 12),
                _fadeSlide(3, TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(labelText: '${AppStrings.get('phone_number')} (optional)', prefixIcon: const Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                )),
                const SizedBox(height: 24),
                _fadeSlide(4, _sectionHeader(Icons.lock_rounded, 'Security')),
                const SizedBox(height: 12),
                _fadeSlide(5, TextFormField(
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
                  validator: (v) => v == null || v.length < 6 ? AppStrings.get('min_password') : null,
                  onChanged: (_) => setState(() {}),
                )),
                if (_passCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _fadeSlide(5, Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_passwordStrength + 1) / 5,
                        backgroundColor: AppTheme.greyShade(context, 200),
                        color: _strengthColor,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(_strengthLabel, style: TextStyle(fontSize: 11, color: _strengthColor, fontWeight: FontWeight.w600)),
                    ),
                  ])),
                ],
                const SizedBox(height: 12),
                _fadeSlide(5, TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(labelText: AppStrings.get('confirm_password'), prefixIcon: const Icon(Icons.lock_rounded)),
                  validator: (v) => v != _passCtrl.text ? AppStrings.get('passwords_mismatch') : null,
                )),
                const SizedBox(height: 36),
                _fadeSlide(6, SizedBox(
                  width: double.infinity, height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(AppStrings.get('register'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
                _fadeSlide(6, Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(AppStrings.get('already_have_account'), style: const TextStyle(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, CustomRoute(page: const LoginPage())),
                    child: Text(AppStrings.get('login'), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primary.withValues(alpha: 0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
    ]);
  }

  Widget _fadeSlide(int index, Widget child) {
    return FadeTransition(
      opacity: _animCtrl.drive(Tween(begin: 0.0, end: 1.0)),
      child: SlideTransition(
        position: _animCtrl.drive(Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: Interval(index * 0.08, 0.5 + index * 0.06, curve: Curves.easeOutCubic)))),
        child: child,
      ),
    );
  }
}
