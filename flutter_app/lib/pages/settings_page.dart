import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDarkToggle;
  final VoidCallback onLanguageToggle;
  final bool notificationsEnabled;
  final VoidCallback onNotificationToggle;
  const SettingsPage({super.key, required this.isDark, required this.onDarkToggle, required this.onLanguageToggle, required this.notificationsEnabled, required this.onNotificationToggle});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTheme.gradientAppBar(AppStrings.get('settings'), leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  SwitchListTile(
                    title: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(AppStrings.get('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    value: widget.isDark,
                    onChanged: (_) => widget.onDarkToggle(),
                    activeColor: AppTheme.primary,
                  ),
                  const Divider(height: 1, indent: 60, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.language_rounded, color: AppTheme.accent, size: 20),
                    ),
                    title: Text(AppStrings.get('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppStrings.isTamil ? 'தமிழ்' : 'English', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ),
                    onTap: () { widget.onLanguageToggle(); setState(() {}); },
                  ),
                  const Divider(height: 1, indent: 60, endIndent: 16),
                  SwitchListTile(
                    title: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.notifications_rounded, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(AppStrings.get('daily_reminder'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    value: widget.notificationsEnabled,
                    onChanged: (_) { widget.onNotificationToggle(); setState(() {}); },
                    activeColor: Colors.green,
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cloud_download_rounded, color: AppTheme.warning, size: 20),
              ),
              title: const Text('Claim Old Data', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Migrate pre-existing data to your account', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              onTap: () async {
                final confirmed = await AppTheme.showConfirm(
                  context,
                  'Claim Old Data',
                  'This will assign all unowned data to your institution. Continue?',
                );
                if (!confirmed) return;
                try {
                  final result = await ApiService.claimOldData();
                  if (context.mounted) {
                    AppTheme.showSnack(context, 'Claimed: ${result['migrated'] ?? 'OK'}');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppTheme.showSnack(context, 'Failed: $e', isError: true);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
