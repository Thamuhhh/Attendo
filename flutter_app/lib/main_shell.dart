import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'pages/onboarding_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/students_page.dart';
import 'pages/attendance_page.dart';
import 'pages/fees_page.dart';
import 'pages/report_page.dart';
import 'pages/settings_page.dart';
import 'l10n/strings.dart';
import 'providers/auth_provider.dart';
import 'widgets/widgets.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageCtrl;
  final _dashboardKey = GlobalKey<DashboardPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _pages = [
      DashboardPage(key: _dashboardKey),
      const StudentsPage(),
      const AttendancePage(),
      const FeesPage(),
      const ReportPage(),
    ];
  }

  List<String> get _titles => [
    AppStrings.get('dashboard'),
    AppStrings.get('students'),
    AppStrings.get('attendance'),
    AppStrings.get('fees'),
    AppStrings.get('report'),
  ];

  final _outlinedIcons = const [
    Icons.dashboard_outlined,
    Icons.people_outlined,
    Icons.checklist_outlined,
    Icons.payments_outlined,
    Icons.bar_chart_outlined,
  ];

  final _filledIcons = const [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.checklist_rounded,
    Icons.payments_rounded,
    Icons.bar_chart_rounded,
  ];

  @override
  void dispose() { ApiService.stopKeepAlive(); _pageCtrl.dispose(); super.dispose(); }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (route) => false,
      );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    final titles = _titles;

    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        backgroundColor: AppTheme.cardColor(context),
        child: Container(
          color: AppTheme.cardColor(context),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment(-0.2, -0.5),
                      end: Alignment(0.8, 1.2),
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Row(
                    children: [
                      GradientAvatar(
                        name: AuthService.institutionName ?? 'Attendo',
                        size: 56,
                        fontSize: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService.institutionName ?? AppStrings.get('my_institution'),
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AuthService.institutionEmail ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: titles[0],
                  isSelected: _currentIndex == 0,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 0); },
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: titles[1],
                  isSelected: _currentIndex == 1,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 1); },
                ),
                _DrawerItem(
                  icon: Icons.checklist_rounded,
                  label: titles[2],
                  isSelected: _currentIndex == 2,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 2); },
                ),
                _DrawerItem(
                  icon: Icons.payments_rounded,
                  label: titles[3],
                  isSelected: _currentIndex == 3,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 3); },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: titles[4],
                  isSelected: _currentIndex == 4,
                  onTap: () { Navigator.pop(context); _pageCtrl.animateToPage(4, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); setState(() => _currentIndex = 4); },
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: AppStrings.get('settings'),
                  isSelected: false,
                  onTap: () { Navigator.pop(context); Navigator.push(context, CustomRoute(page: const SettingsPage())); },
                ),
                const SizedBox(height: 8),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.greyShade(context, 200)),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: d ? 0.3 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                    ),
                    title: Text(AppStrings.get('logout'), style: TextStyle(color: d ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardColor(context),
                          title: Text(AppStrings.get('logout'), style: TextStyle(color: d ? Colors.white : AppTheme.textPrimary)),
                          content: Text(AppStrings.get('logout_confirm'), style: TextStyle(color: d ? Colors.grey.shade300 : AppTheme.textSecondary)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('cancel'), style: TextStyle(color: d ? Colors.grey.shade400 : Colors.grey.shade600))),
                            TextButton(
                              onPressed: () { Navigator.pop(ctx); _logout(); },
                              child: Text(AppStrings.get('logout'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
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
          AppTheme.whatsappAppBar('Attendo', leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          )),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                if (i == 0) _dashboardKey.currentState?.load();
              },
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (d ? AppTheme.cardBgDark : Colors.white).withValues(alpha: d ? 0.9 : 0.85),
              border: Border(
                top: BorderSide(
                  color: d ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) {
                _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
                setState(() => _currentIndex = i);
              },
              elevation: 0,
              backgroundColor: Colors.transparent,
              indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
              height: 68,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 250),
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              destinations: List.generate(5, (i) => NavigationDestination(
                icon: Icon(_outlinedIcons[i], color: AppTheme.greyShade(context, 500)),
                selectedIcon: Icon(_filledIcons[i], color: AppTheme.primary),
                label: titles[i],
              )),
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
    final d = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight)
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
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: d ? 0.3 : 0.06),
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
                      color: isSelected ? Colors.white : (d ? Colors.grey.shade200 : AppTheme.textPrimary),
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
