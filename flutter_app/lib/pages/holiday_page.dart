import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class HolidayPage extends StatefulWidget {
  final Set<String> currentHolidays;
  final ValueChanged<Set<String>> onChanged;
  const HolidayPage({super.key, required this.currentHolidays, required this.onChanged});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  late Set<String> _holidays;

  @override
  void initState() {
    super.initState();
    _holidays = Set.from(widget.currentHolidays);
  }

  void _add() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: AppTheme.lightTheme.colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (p == null) return;
    final dateStr = '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
    try {
      await ApiService.addHoliday(dateStr);
      setState(() => _holidays.add(dateStr));
      widget.onChanged(_holidays);
      if (mounted) AppTheme.showToast(context, AppStrings.get('holiday_added'));
    } catch (e) {
      if (mounted) AppTheme.showToast(context, AppStrings.get('holiday_add_failed'), isError: true);
    }
  }

  Future<void> _remove(String date) async {
    final confirmed = await AppTheme.showConfirm(context, AppStrings.get('remove_holiday'),
      AppStrings.get('remove_holiday_confirm'), confirmLabel: AppStrings.get('remove'));
    if (!confirmed) return;
    try {
      await ApiService.removeHoliday(date);
      setState(() => _holidays.remove(date));
      widget.onChanged(_holidays);
      if (mounted) AppTheme.showToast(context, AppStrings.get('holiday_removed'));
    } catch (e) {
      if (mounted) AppTheme.showToast(context, AppStrings.get('holiday_remove_failed'), isError: true);
    }
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${days[d.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    final sorted = _holidays.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: BackgroundDecoration(
        child: Column(children: [
          AppTheme.gradientAppBar(AppStrings.get('holidays'), leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )),
          if (sorted.isEmpty)
            Expanded(child: EmptyState(
              icon: Icons.luggage_rounded,
              title: AppStrings.get('no_holidays'),
              subtitle: AppStrings.get('tap_to_add_holiday'),
            ))
          else
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: sorted.map((date) => Dismissible(
                key: ValueKey(date),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                confirmDismiss: (_) async => AppTheme.showConfirm(context, AppStrings.get('remove_holiday'),
                  AppStrings.get('remove_holiday_confirm'), confirmLabel: 'Remove'),
                onDismissed: (_) async {
                  try {
                    await ApiService.removeHoliday(date);
                    setState(() => _holidays.remove(date));
                    widget.onChanged(_holidays);
                    if (mounted) AppTheme.showToast(context, AppStrings.get('holiday_removed'));
                  } catch (e) {
                    if (mounted) AppTheme.showToast(context, AppStrings.get('remove_holiday_failed'), isError: true);
                  }
                },
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: d ? 0.3 : 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.celebration_rounded, color: AppTheme.warning, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatDate(date), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: d ? Colors.white : AppTheme.textPrimary)),
                      ],
                    )),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppTheme.greyShade(context, 400), size: 20),
                      onPressed: () => _remove(date),
                    ),
                  ]),
                ),
              )).toList(),
            )),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
