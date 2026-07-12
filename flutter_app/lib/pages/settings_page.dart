import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../services/offline_db.dart';
import '../utils/app_version.dart';
import '../widgets/widgets.dart';
import 'reminders_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with SingleTickerProviderStateMixin {
  int _pendingCount = 0;
  bool _loadingSync = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadPendingCount();
    SyncService.onStatusChanged = (_) { if (mounted) setState(() {}); };
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _loadPendingCount() async {
    setState(() => _loadingSync = true);
    final count = await OfflineDb.pendingCount();
    if (mounted) setState(() { _pendingCount = count; _loadingSync = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final d = AppTheme.isDark(context);
    final instName = AuthService.institutionName ?? 'Attendo';
    final instEmail = AuthService.institutionEmail ?? '';

    return Scaffold(
      body: BackgroundDecoration(
        child: Column(
          children: [
            AppTheme.gradientAppBar(AppStrings.get('settings'), leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildProfileCard(instName, instEmail, d),
                  const SizedBox(height: 24),
                  _sectionHeader(AppStrings.get('preferences'), d),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(children: [
                      _SettingTile(
                        icon: settings.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconColor: AppTheme.primary,
                        title: AppStrings.get('dark_mode'),
                        trailing: Switch(
                          value: settings.isDark,
                          onChanged: (_) => ref.read(settingsProvider.notifier).toggleDark(),
                          activeColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.language_rounded,
                        iconColor: AppTheme.accent,
                        title: AppStrings.get('language'),
                        subtitle: AppStrings.isTamil ? 'தமிழ்' : 'English',
                        onTap: () { ref.read(settingsProvider.notifier).toggleLanguage(); setState(() {}); },
                      ),
                      _divider(),
                      _SettingTile(
                        icon: Icons.notifications_rounded,
                        iconColor: AppTheme.primary,
                        title: AppStrings.get('daily_reminder'),
                        trailing: Switch(
                          value: settings.notificationsEnabled,
                          onChanged: (_) { ref.read(settingsProvider.notifier).toggleNotifications(); setState(() {}); },
                          activeColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.tune_rounded,
                        iconColor: AppTheme.accent,
                        title: 'Manage Reminders',
                        subtitle: 'Multiple profiles, days & smart detection',
                        onTap: () => Navigator.push(context, CustomRoute(page: const RemindersPage())),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(AppStrings.get('data_section'), d),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(children: [
                      _SettingTile(
                        icon: SyncService.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        iconColor: SyncService.isOnline ? AppTheme.success : AppTheme.danger,
                        title: AppStrings.get('sync_now'),
                        subtitle: _syncSubtitle(),
                        trailing: _syncTrailing(),
                        onTap: _handleSync,
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppTheme.danger,
                        title: AppStrings.get('clear_data'),
                        subtitle: '${_pendingCount} ${AppStrings.get('pending_sync').replaceAll('{count}', '')}'.trim(),
                        onTap: _handleClear,
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.cloud_download_rounded,
                        iconColor: AppTheme.warning,
                        title: AppStrings.get('claim_old_data'),
                        subtitle: AppStrings.get('migrate_subtitle'),
                        onTap: _handleClaim,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(AppStrings.get('about_section'), d),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(children: [
                      _SettingTile.nav(
                        icon: Icons.star_rounded,
                        iconColor: AppTheme.warning,
                        title: AppStrings.get('rate_app'),
                        onTap: () => AppTheme.showSnack(context, '⭐ ${AppStrings.get('rate_app')}!'),
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.share_rounded,
                        iconColor: AppTheme.accent,
                        title: AppStrings.get('share_app'),
                        onTap: () {
                          AppTheme.showToast(context, AppStrings.get('share_text'));
                        },
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppTheme.primary,
                        title: AppStrings.get('contact_support'),
                        subtitle: AppStrings.get('support_email'),
                        onTap: () {
                          AppTheme.showToast(context, '${AppStrings.get('support_email')} (${AppStrings.get('copied')})');
                        },
                      ),
                      _divider(),
                      _SettingTile(
                        icon: Icons.code_rounded,
                        iconColor: AppTheme.textSecondary,
                        title: AppStrings.get('developer'),
                        trailing: Text('@anomaly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: d ? AppTheme.textSecondaryDark : AppTheme.textSecondary)),
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppTheme.primary,
                        title: AppStrings.get('app_version'),
                        onTap: () {},
                      ),
                      _divider(),
                      _SettingTile.nav(
                        icon: Icons.system_update_rounded,
                        iconColor: AppTheme.warning,
                        title: AppStrings.get('check_update'),
                        onTap: _checkUpdate,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, bool d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: d ? 0.25 : 0.08), AppTheme.primary.withValues(alpha: d ? 0.05 : 0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: d ? 0.2 : 0.08)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: d ? 0.1 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        GradientAvatar(name: name, size: 56, fontSize: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: d ? Colors.white : AppTheme.textPrimary)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 13, color: d ? AppTheme.textSecondaryDark : AppTheme.textSecondary)),
              ],
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SyncService.isOnline ? AppTheme.success : AppTheme.danger,
              boxShadow: [
                BoxShadow(
                  color: (SyncService.isOnline ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.5 * _pulseAnim.value),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String title, bool d) {
    return Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(2),
      )),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary.withValues(alpha: d ? 0.8 : 0.9),
        letterSpacing: 1.5,
      )),
    ]);
  }

  Widget _syncSubtitle() {
    return Row(children: [
      AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyncService.isOnline ? AppTheme.success : AppTheme.danger,
            boxShadow: [
              BoxShadow(
                color: (SyncService.isOnline ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.5 * _pulseAnim.value),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        _loadingSync
            ? AppStrings.get('loading')
            : SyncService.isOnline
                ? '${AppStrings.get('online_status')} · ${AppStrings.get('pending_sync').replaceAll('{count}', '$_pendingCount')}'
                : AppStrings.get('offline_status'),
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    ]);
  }

  Widget _syncTrailing() {
    if (_loadingSync) {
      return SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accent));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh_rounded, size: 14, color: AppTheme.accent),
          const SizedBox(width: 4),
          Text(AppStrings.get('sync_now'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent)),
        ],
      ),
    );
  }

  Widget _versionBadge(bool d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: d ? 0.25 : 0.1), AppTheme.primary.withValues(alpha: d ? 0.1 : 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: d ? 0.2 : 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag_rounded, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text('v${AppVersion.current}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Future<void> _checkUpdate() async {
    try {
      final data = await ApiService.getAppVersion();
      final remoteVer = data['version'] as String? ?? '1.0.0';
      final apkUrl = data['apkUrl'] as String? ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      if (!mounted) return;

      if (remoteVer.isEmpty || apkUrl.isEmpty) {
        AppTheme.showSnack(context, 'Unable to check update');
        return;
      }

      if (!AppVersion.isNewer(remoteVer)) {
        AppTheme.showSnack(context, 'You are on the latest version (v${AppVersion.current})');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (ctx) => PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: Row(children: [
              const Icon(Icons.system_update_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(forceUpdate ? 'Update Required' : 'Update Available'),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $remoteVer is available. You have ${AppVersion.current}.'),
                if (forceUpdate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is mandatory. Please update to continue using the app.',
                          style: TextStyle(fontSize: 13, color: AppTheme.danger),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later'),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Now'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) AppTheme.showSnack(context, 'Unable to open download link', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'Update check failed', isError: true);
    }
  }

  Future<void> _handleSync() async {
    if (!SyncService.isOnline) {
      AppTheme.showSnack(context, AppStrings.get('offline_status'), isError: true);
      return;
    }
    setState(() => _loadingSync = true);
    await SyncService.syncNow();
    await _loadPendingCount();
    if (mounted) AppTheme.showSnack(context, AppStrings.get('success'));
  }

  Future<void> _handleClear() async {
    final confirmed = await AppTheme.showConfirm(context, AppStrings.get('clear_data'), AppStrings.get('clear_data_confirm'));
    if (!confirmed) return;
    try {
      await OfflineDb.deleteSyncedOlderThan(Duration.zero);
      await _loadPendingCount();
      if (mounted) AppTheme.showSnack(context, AppStrings.get('clear_data_success'));
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, AppStrings.get('clear_data_failed'), isError: true);
    }
  }

  Future<void> _handleClaim() async {
    final confirmed = await AppTheme.showConfirm(context, AppStrings.get('claim_old_data'), AppStrings.get('migrate_confirm'));
    if (!confirmed) return;
    try {
      final result = await ApiService.claimOldData();
      if (mounted) {
        AppTheme.showSnack(context, AppStrings.get('claim_success').replaceAll('{count}', '${result['migrated'] ?? 'OK'}'));
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, AppStrings.get('claim_failed').replaceAll('{error}', '$e'), isError: true);
    }
  }

  static Widget _divider() => const Divider(height: 1, indent: 60, endIndent: 16);
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = false,
  });

  _SettingTile.nav({
    required this.icon,
    required this.iconColor,
    required this.title,
    String? subtitle,
    required this.onTap,
  }) : showArrow = true,
       subtitle = subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)) : null,
       trailing = null;

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: d ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: d ? 0.15 : 0.06)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: d ? Colors.white : AppTheme.textPrimary)),
          subtitle: subtitle,
          trailing: showArrow
              ? Icon(Icons.chevron_right_rounded, color: d ? AppTheme.greyShade(context, 500) : Colors.grey.shade400, size: 22)
              : trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          minVerticalPadding: 8,
        ),
      ),
    );
  }
}
