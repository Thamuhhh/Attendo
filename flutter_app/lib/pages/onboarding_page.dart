import 'package:flutter/material.dart';
import '../theme.dart';
import 'register_page.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDarkToggle;
  final VoidCallback onLanguageToggle;
  final bool notificationsEnabled;
  final VoidCallback onNotificationToggle;
  const OnboardingPage({super.key, this.isDark = false, required this.onDarkToggle, required this.onLanguageToggle, this.notificationsEnabled = false, required this.onNotificationToggle});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _pulseCtrl;
  int _current = 0;

  final _slides = [
    _SlideData(
      imageUrl: 'https://res.cloudinary.com/db33m8gqe/image/upload/q_auto/f_auto/v1781682894/New_Project_elxu7s.png',
      title: 'Manage Your\nTuition Center',
      desc: 'Track student attendance, fees, and reports all in one place. Simplify your tuition management.',
      color: AppTheme.primary,
    ),
    _SlideData(
      icon: Icons.checklist_rounded,
      title: 'Smart\nAttendance Tracking',
      desc: 'Mark attendance with a single tap. View daily, monthly reports for every student.',
      color: AppTheme.accent,
    ),
    _SlideData(
      icon: Icons.payments_rounded,
      title: 'Fee Management\nMade Easy',
      desc: 'Track paid & unpaid months. Know exactly who has paid and who hasn\'t.',
      color: const Color(0xFF7C3AED),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in _slides) {
      if (s.imageUrl != null) precacheImage(NetworkImage(s.imageUrl!), context);
    }
  }

  @override
  void dispose() { _pageCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _slides[_current].color.withValues(alpha: 0.04),
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _current = i),
                children: _slides.map((s) => _SlideWidget(data: s, pulseCtrl: _pulseCtrl)).toList(),
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(colors: [_slides[i].color, _slides[i].color.withValues(alpha: 0.5)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                      : null,
                  color: isActive ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive ? [BoxShadow(color: _slides[i].color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [_slides[_current].color, _slides[_current].color.withValues(alpha: 0.75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [BoxShadow(color: _slides[_current].color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (_current < _slides.length - 1) {
                      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage(isDark: widget.isDark, onDarkToggle: widget.onDarkToggle, onLanguageToggle: widget.onLanguageToggle, notificationsEnabled: widget.notificationsEnabled, onNotificationToggle: widget.onNotificationToggle)));
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _current < _slides.length - 1 ? 'Next' : 'Get Started',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _current < _slides.length - 1 ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded,
                          color: Colors.white, size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_current < _slides.length - 1)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage(isDark: widget.isDark, onDarkToggle: widget.onDarkToggle, onLanguageToggle: widget.onLanguageToggle, notificationsEnabled: widget.notificationsEnabled, onNotificationToggle: widget.onNotificationToggle))),
              child: Text('Skip', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade500)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage(isDark: widget.isDark, onDarkToggle: widget.onDarkToggle, onLanguageToggle: widget.onLanguageToggle, notificationsEnabled: widget.notificationsEnabled, onNotificationToggle: widget.onNotificationToggle))),
                child: Text('Login', style: TextStyle(color: _slides[_current].color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData? icon;
  final String? imageUrl;
  final String title;
  final String desc;
  final Color color;
  _SlideData({this.icon, this.imageUrl, required this.title, required this.desc, required this.color});
}

class _SlideWidget extends StatelessWidget {
  final _SlideData data;
  final AnimationController pulseCtrl;
  const _SlideWidget({required this.data, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (ctx, _) {
              final s = 1.0 + pulseCtrl.value * 0.03;
              return Transform.scale(
                scale: s,
                child: data.imageUrl != null
                    ? Image.network(data.imageUrl!, width: 140, height: 140, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(data.icon ?? Icons.school, size: 72, color: data.color))
                    : Icon(data.icon, size: 72, color: data.color),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.6),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
