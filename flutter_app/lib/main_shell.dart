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
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://res.cloudinary.com/db33m8gqe/image/upload/q_auto/f_auto/v1781682894/New_Project_elxu7s.png',
                          width: 52, height: 52,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              (AuthService.institutionName ?? 'T')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService.institutionName ?? 'My Institution',
                              style: const TextStyle(fontSize: 17, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AuthService.institutionEmail ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Menu items
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 0); },
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Students',
                  isSelected: _currentIndex == 1,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 1); },
                ),
                _DrawerItem(
                  icon: Icons.checklist_rounded,
                  label: 'Attendance',
                  isSelected: _currentIndex == 2,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 2); },
                ),
                _DrawerItem(
                  icon: Icons.payments_rounded,
                  label: 'Fees',
                  isSelected: _currentIndex == 3,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 3); },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report',
                  isSelected: _currentIndex == 4,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(4, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 4); },
                ),
                const Spacer(),
                // Logout
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                    ),
                    title: const Text('Logout', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
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
                              child: const Text('Logout', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? null : Colors.transparent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
