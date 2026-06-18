import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/strings.dart';
import '../services/notification_service.dart';

class SettingsState {
  final bool isDark;
  final bool notificationsEnabled;

  const SettingsState({this.isDark = false, this.notificationsEnabled = true});
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleDark() {
    state = SettingsState(isDark: !state.isDark, notificationsEnabled: state.notificationsEnabled);
  }

  void toggleLanguage() {
    AppStrings.setLanguage(!AppStrings.isTamil);
  }

  void toggleNotifications() {
    final newVal = !state.notificationsEnabled;
    NotificationService().setEnabled(newVal);
    state = SettingsState(isDark: state.isDark, notificationsEnabled: newVal);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
