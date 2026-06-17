import 'package:flutter/material.dart';
import '../theme.dart';
import 'register_page.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
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
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _current = i),
              children: _slides.map((s) => _SlideWidget(data: s)).toList(),
            ),
          ),
          _buildBottom(),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
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
                  color: isActive ? AppTheme.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_current < _slides.length - 1) {
                  _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                _current < _slides.length - 1 ? 'Next' : 'Get Started',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_current < _slides.length - 1)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Skip', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text('Login', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
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
  const _SlideWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(40),
            ),
            child: data.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(data.imageUrl!, width: 100, height: 100, fit: BoxFit.contain),
                  )
                : Icon(data.icon, size: 72, color: data.color),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
