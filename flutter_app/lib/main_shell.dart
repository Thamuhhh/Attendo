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

  void _navigate(int index) {
    Navigator.pop(context);
    _pageCtrl.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    setState(() => _currentIndex = index);
  }

  void _openSettings() {
    Navigator.pop(context);
    Navigator.push(context, CustomRoute(page: const SettingsPage()));
  }

  void _confirmLogout() {
    final d = AppTheme.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(AppStrings.get('logout'), style: TextStyle(color: d ? Colors.white : AppTheme.textPrimary)),
        content: Text(AppStrings.get('logout_confirm'), style: TextStyle(color: d ? AppTheme.textSecondaryDark : AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('cancel'), style: TextStyle(color: d ? AppTheme.greyShade(context, 400) : Colors.grey.shade600))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _logout(); },
            child: Text(AppStrings.get('logout'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    final titles = _titles;

    return Scaffold(
      extendBody: false,
      drawer: Drawer(
        backgroundColor: AppTheme.cardColor(context),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  children: [
                    GradientAvatar(
                      name: AuthService.institutionName ?? 'Attendo',
                      size: 48,
                      fontSize: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthService.institutionName ?? AppStrings.get('my_institution'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: d ? Colors.white : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AuthService.institutionEmail ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: d ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: _filledIcons[0],
                      label: titles[0],
                      isSelected: _currentIndex == 0,
                      onTap: () => _navigate(0),
                    ),
                    _DrawerItem(
                      icon: _filledIcons[1],
                      label: titles[1],
                      isSelected: _currentIndex == 1,
                      onTap: () => _navigate(1),
                    ),
                    _DrawerItem(
                      icon: _filledIcons[2],
                      label: titles[2],
                      isSelected: _currentIndex == 2,
                      onTap: () => _navigate(2),
                    ),
                    _DrawerItem(
                      icon: _filledIcons[3],
                      label: titles[3],
                      isSelected: _currentIndex == 3,
                      onTap: () => _navigate(3),
                    ),
                    _DrawerItem(
                      icon: _filledIcons[4],
                      label: titles[4],
                      isSelected: _currentIndex == 4,
                      onTap: () => _navigate(4),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      label: AppStrings.get('settings'),
                      isSelected: false,
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: AppStrings.get('logout'),
                isSelected: false,
                isLogout: true,
                onTap: _confirmLogout,
              ),
              const SizedBox(height: 8),
            ],
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
              physics: const PageScrollPhysics(),
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
        child: Container(
          decoration: BoxDecoration(
            color: d ? AppTheme.cardBgDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: d ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: d ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
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
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isLogout;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    final accent = isLogout ? AppTheme.danger : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: d ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    left: 0, top: 8, bottom: 8,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withValues(alpha: d ? 0.25 : 0.12)
                              : accent.withValues(alpha: d ? 0.2 : 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 19, color: isSelected ? accent : (d ? AppTheme.greyShade(context, 400) : AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? accent
                              : (d ? AppTheme.greyShade(context, 400) : AppTheme.textSecondary),
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
    );
  }
}
