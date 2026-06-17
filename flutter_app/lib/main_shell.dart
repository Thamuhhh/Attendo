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
                const SizedBox(height: 48),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: Text(
                    (AuthService.institutionName ?? 'T')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) { _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = i); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people_rounded), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist_rounded), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments_rounded), label: 'Fees'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Report'),
        ],
      ),
    );
  }
}
