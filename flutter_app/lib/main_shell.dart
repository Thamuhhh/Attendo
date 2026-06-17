import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'pages/onboarding_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/students_page.dart';
import 'pages/attendance_page.dart';
import 'pages/fees_page.dart';
import 'pages/report_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Shell();
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _currentIndex = 0;
  late final PageController _pageCtrl;

  final _pages = const [
    DashboardPage(),
    StudentsPage(),
    AttendancePage(),
    FeesPage(),
    ReportPage(),
  ];

  final _titles = ['Dashboard', 'Students', 'Attendance', 'Fees', 'Report'];

  final _selectedIcons = const [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.checklist_rounded,
    Icons.payments_rounded,
    Icons.bar_chart_rounded,
  ];

  final _outlinedIcons = const [
    Icons.dashboard_outlined,
    Icons.people_outlined,
    Icons.checklist_outlined,
    Icons.payments_outlined,
    Icons.bar_chart_outlined,
  ];

  @override
  void initState() { super.initState(); _pageCtrl = PageController(); }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _logout() async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://res.cloudinary.com/db33m8gqe/image/upload/q_auto/f_auto/v1781682894/New_Project_elxu7s.png',
                    width: 100, height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: Text(
                        (AuthService.institutionName ?? 'T')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AuthService.institutionName ?? 'My Institution',
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  AuthService.institutionEmail ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                ),
                const Spacer(),
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                  title: const Text('Logout', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () { Navigator.pop(ctx); _logout(); },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          AppTheme.gradientAppBar(_titles[_currentIndex], leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          )),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: List.generate(5, (i) {
                  final isSelected = i == _currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                        setState(() => _currentIndex = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.all(isSelected ? 6 : 4),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? _selectedIcons[i] : _outlinedIcons[i],
                              size: isSelected ? 22 : 20,
                              color: isSelected ? Colors.white : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _titles[i],
                              style: TextStyle(
                                fontSize: isSelected ? 11 : 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
