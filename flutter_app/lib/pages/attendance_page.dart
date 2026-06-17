import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  Map<String, String> _statusMap = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await ApiService.getStudents();
      List<AttendanceRecord> existing = [];
      try { existing = await ApiService.getAttendanceByDate(_dateStr()); } catch (_) {}
      final sm = <String, String>{};
      for (final s in students) {
        final f = existing.where((a) => a.studentId == s.id);
        sm[s.id] = f.isNotEmpty ? f.first.status : 'absent';
      }
      if (mounted) setState(() { _students = students; _statusMap = sm; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Error: $e', isError: true); }
    }
  }

  String _dateStr() => '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String _displayDate() {
    final d = _selectedDate;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool get _isToday => _dateStr() == '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: AppTheme.lightTheme.colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (p != null) { setState(() => _selectedDate = p); _load(); }
  }

  void _toggle(String id) { setState(() => _statusMap[id] = _statusMap[id] == 'present' ? 'absent' : 'present'); }

  void _markAll(String s) { setState(() { for (final st in _students) _statusMap[st.id] = s; }); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final records = _statusMap.entries
          .where((e) => _students.any((s) => s.id == e.key))
          .map((e) => {'studentId': e.key, 'status': e.value})
          .toList();
      await ApiService.saveAttendance(_dateStr(), records);
      if (mounted) AppTheme.showSnack(context, 'Attendance saved for $_displayDate()');
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'Save failed', isError: true);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pc = _statusMap.values.where((v) => v == 'present').length;
    final ac = _statusMap.values.where((v) => v == 'absent').length;

    return BackgroundDecoration(
      child: Column(children: [
        GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(4),
          child: Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('ATTENDANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
                        if (_isToday) ...[const SizedBox(width: 8), Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: const Text('TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.success)),
                        )],
                      ]),
                      const SizedBox(height: 4),
                      Text(_displayDate(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ],
                  )),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary, size: 28),
                ]),
              ),
            ),
            if (!_loading && _students.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  _miniBadge(Icons.check_circle_rounded, '$pc Present', AppTheme.success),
                  const SizedBox(width: 12),
                  _miniBadge(Icons.cancel_rounded, '$ac Absent', AppTheme.danger),
                  const Spacer(),
                  ScaleOnPress(
                    onTap: () => _markAll('present'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('All P', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.success)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ScaleOnPress(
                    onTap: () => _markAll('absent'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('All A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
        Expanded(
          child: _loading
              ? ListView.builder(itemCount: 6, itemBuilder: (_, __) => const ShimmerCard())
              : _students.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_add_disabled_rounded, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No students added yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 6),
                      Text('Go to Students tab to add', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ]))
                  : RefreshIndicator(
                      color: AppTheme.primary, onRefresh: _load,
                      child: StaggeredList(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: _students.length,
                        itemBuilder: (_, i) {
                          final s = _students[i];
                          final ip = _statusMap[s.id] == 'present';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _toggle(s.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    width: ip ? 48 : 44, height: ip ? 48 : 44,
                                    decoration: BoxDecoration(
                                      color: ip ? AppTheme.success.withValues(alpha: 0.12) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(ip ? 14 : 12),
                                      border: ip ? Border.all(color: AppTheme.success.withValues(alpha: 0.3)) : null,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: ip
                                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 26, key: ValueKey('p'))
                                          : const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey, size: 24, key: ValueKey('a')),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 300),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ip ? AppTheme.success : AppTheme.danger),
                                        child: Text(ip ? 'Present' : 'Absent'),
                                      ),
                                    ],
                                  )),
                                  AnimatedScale(
                                    scale: ip ? 1 : 0.85,
                                    duration: const Duration(milliseconds: 300),
                                    child: Switch(
                                      value: ip,
                                      activeTrackColor: AppTheme.success.withValues(alpha: 0.3),
                                      onChanged: (_) => _toggle(s.id),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving || _students.isEmpty ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Attendance', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _miniBadge(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}
