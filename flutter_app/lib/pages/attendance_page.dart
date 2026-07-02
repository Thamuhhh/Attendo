import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/offline_db.dart';
import '../services/sync_service.dart';
import '../widgets/widgets.dart';
import 'holiday_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  Map<String, String> _statusMap = {};
  bool _loading = true;
  bool _saving = false;
  final _searchCtrl = TextEditingController();
  Set<String> _holidays = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filter);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredStudents = q.isEmpty
          ? _allStudents
          : _allStudents.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getStudents(),
        ApiService.getHolidays(),
      ]);
      final students = results[0] as List<Student>;
      final holidays = results[1] as List<String>;
      List<AttendanceRecord> existing = [];
      try { existing = await ApiService.getAttendanceByDate(_dateStr()); } catch (_) {}
      final sm = <String, String>{};
      for (final s in students) {
        final f = existing.where((a) => a.studentId == s.id);
        sm[s.id] = f.isNotEmpty ? f.first.status : 'absent';
      }
      if (mounted) setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _statusMap = sm;
        _holidays = holidays.toSet();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = AppStrings.get('failed_to_load_attendance'); });
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
  bool get _isHoliday => _holidays.contains(_dateStr());

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

  Future<void> _openHolidayManager() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => HolidayPage(
        currentHolidays: _holidays,
        onChanged: (updated) {
          setState(() => _holidays = updated);
        },
      ),
    ));
    _load();
  }

  void _toggle(String id) { setState(() => _statusMap[id] = _statusMap[id] == 'present' ? 'absent' : 'present'); }

  void _markAll(String s) { setState(() { for (final st in _allStudents) _statusMap[st.id] = s; }); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final records = _statusMap.entries
          .where((e) => _allStudents.any((s) => s.id == e.key))
          .map((e) => {'studentId': e.key, 'status': e.value})
          .toList();
      if (SyncService.isOnline) {
        await ApiService.saveAttendance(_dateStr(), records);
        if (mounted) AppTheme.showSnack(context, AppStrings.get('saved_success'));
      } else {
        await OfflineDb.saveAttendance(_dateStr(), records);
        if (mounted) AppTheme.showSnack(context, 'Saved offline — will sync when online');
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, AppStrings.get('save_failed'), isError: true);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final pc = _statusMap.values.where((v) => v == 'present').length;
    final ac = _statusMap.values.where((v) => v == 'absent').length;
    final d = AppTheme.isDark(context);

    return BackgroundDecoration(
      child: Column(children: [
        GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: EdgeInsets.zero,
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
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(AppStrings.get('attendance').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.greyShade(context, 500), letterSpacing: 1)),
                        if (_isToday) ...[const SizedBox(width: 8), Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: d ? 0.2 : 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(AppStrings.get('today').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.success)),
                        )],
                        if (_isHoliday) ...[const SizedBox(width: 8), Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: d ? 0.2 : 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(AppStrings.get('holiday').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.warning)),
                        )],
                      ]),
                      const SizedBox(height: 4),
                      Text(_displayDate(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: d ? Colors.white : AppTheme.textPrimary)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.greyShade(context, 100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, color: AppTheme.textSecondary, size: 20),
                  ),
                ]),
              ),
            ),
            if (!_loading && _allStudents.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: d ? 0.08 : 0.04), AppTheme.primaryLight.withValues(alpha: d ? 0.04 : 0.02)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: d ? 0.1 : 0.06)),
                ),
                child: Column(children: [
                  Row(children: [
                    _miniBadge(context, Icons.check_circle_rounded, AppStrings.get('num_present').replaceAll('{count}', '$pc'), AppTheme.success),
                    const SizedBox(width: 12),
                    _miniBadge(context, Icons.cancel_rounded, AppStrings.get('num_absent').replaceAll('{count}', '$ac'), AppTheme.danger),
                    const Spacer(),
                    ScaleOnPress(
                      onTap: () => _markAll('present'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.success, AppTheme.success.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppTheme.success.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(AppStrings.get('all_present'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ScaleOnPress(
                      onTap: () => _markAll('absent'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.danger, AppTheme.danger.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cancel_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(AppStrings.get('all_absent'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ScaleOnPress(
                      onTap: _openHolidayManager,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: d ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.luggage_rounded, size: 18, color: AppTheme.warning),
                      ),
                    ),
                  ]),
                ]),
              ),
          ]),
        ),
        if (!_loading && _allStudents.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: d ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: AppStrings.get('search_students'),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.greyShade(context, 400)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear_rounded, color: AppTheme.greyShade(context, 400)), onPressed: () { _searchCtrl.clear(); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: AppTheme.cardColor(context), filled: true,
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? ListView.builder(itemCount: 6, itemBuilder: (_, __) => const ShimmerCard())
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : _allStudents.isEmpty
                      ? const Center(child: EmptyState(
                          icon: Icons.person_add_disabled_rounded,
                          title: 'No students added yet',
                          subtitle: 'Go to Students tab to add',
                        ))
                      : RefreshIndicator(
                      color: AppTheme.primary, onRefresh: _load,
                      child: StaggeredList(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (_, i) {
                          final s = _filteredStudents[i];
                          final ip = _statusMap[s.id] == 'present';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: ip ? Border.all(color: AppTheme.success.withValues(alpha: 0.3)) : Border.all(color: Colors.transparent),
                              boxShadow: [
                                BoxShadow(
                                  color: ip ? AppTheme.success.withValues(alpha: d ? 0.08 : 0.04) : Colors.black.withValues(alpha: d ? 0.2 : 0.04),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _toggle(s.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      gradient: ip
                                          ? const LinearGradient(colors: [AppTheme.success, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                          : null,
                                      color: ip ? null : AppTheme.greyShade(context, 100),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: ip ? [BoxShadow(color: AppTheme.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                                    ),
                                    child: Icon(
                                      ip ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: ip ? Colors.white : Colors.grey,
                                      size: ip ? 28 : 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: d ? Colors.white : AppTheme.textPrimary)),
                                      Text(
                                        ip ? AppStrings.get('present') : AppStrings.get('absent'),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ip ? AppTheme.success : AppTheme.danger),
                                      ),
                                    ],
                                  )),
                                  Switch(
                                    value: ip,
                                    activeColor: Colors.white,
                                    activeTrackColor: AppTheme.success.withValues(alpha: 0.5),
                                    onChanged: (_) => _toggle(s.id),
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
                onPressed: _saving || _allStudents.isEmpty ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? AppStrings.get('saving') : AppStrings.get('save_attendance'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _miniBadge(BuildContext context, IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}
