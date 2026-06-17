import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

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
      if (mounted) AppTheme.showToast(context, 'Holiday added');
    } catch (e) {
      if (mounted) AppTheme.showToast(context, 'Failed to add holiday', isError: true);
    }
  }

  Future<void> _remove(String date) async {
    final confirmed = await AppTheme.showConfirm(context, 'Remove Holiday',
      'Remove this holiday from the list?', confirmLabel: 'Remove');
    if (!confirmed) return;
    try {
      await ApiService.removeHoliday(date);
      setState(() => _holidays.remove(date));
      widget.onChanged(_holidays);
      if (mounted) AppTheme.showToast(context, 'Holiday removed');
    } catch (e) {
      if (mounted) AppTheme.showToast(context, 'Failed to remove holiday', isError: true);
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
    final sorted = _holidays.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: Column(children: [
        AppTheme.gradientAppBar('Holidays', leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        )),
        if (sorted.isEmpty)
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.luggage_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No holidays set', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('Tap + to add a holiday', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ])))
        else
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: sorted.map((date) => Dismissible(
              key: ValueKey(date),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              confirmDismiss: (_) async => AppTheme.showConfirm(context, 'Remove Holiday',
                'Remove this holiday from the list?', confirmLabel: 'Remove'),
              onDismissed: (_) async {
                try {
                  await ApiService.removeHoliday(date);
                  setState(() => _holidays.remove(date));
                  widget.onChanged(_holidays);
                  if (mounted) AppTheme.showToast(context, 'Holiday removed');
                } catch (e) {
                  if (mounted) AppTheme.showToast(context, 'Failed to remove holiday', isError: true);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.celebration_rounded, color: AppTheme.warning, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                    ],
                  )),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                    onPressed: () => _remove(date),
                  ),
                ]),
              ),
            )).toList(),
          )),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
