import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../models/student.dart';
import '../widgets/widgets.dart';

class StudentProfilePage extends StatefulWidget {
  final Student student;
  const StudentProfilePage({super.key, required this.student});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _attendanceHistory = [];
  final Map<int, String> _feesMap = {};
  bool _loadingFees = true;
  Set<String> _holidays = {};
  int _calendarYear = DateTime.now().year;
  int _calendarMonth = DateTime.now().month;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAttendanceHistory(widget.student.id),
        ApiService.getFeeRecords(widget.student.id, DateTime.now().year),
        ApiService.getHolidays(),
      ]);
      if (mounted) {
        final att = results[0] as List<Map<String, dynamic>>;
        final fees = results[1] as List;
        final holidays = results[2] as List<String>;
        setState(() {
          _attendanceHistory = att;
          for (final f in fees) { _feesMap[f.month] = f.status; }
          _holidays = holidays.toSet();
          _loading = false;
          _loadingFees = false;
        });
      }
    } catch (_) { if (mounted) setState(() { _loading = false; _loadingFees = false; }); }
  }

  String? _getStatus(String dateStr) {
    if (_holidays.contains(dateStr)) return 'holiday';
    for (final a in _attendanceHistory) {
      if (a['date'] == dateStr) return a['status'];
    }
    return null;
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _dayNames = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
  int _firstWeekday(int year, int month) => (DateTime(year, month, 1).weekday + 6) % 7;

  void _prevMonth() {
    if (_calendarMonth == 1) {
      setState(() { _calendarMonth = 12; _calendarYear--; });
    } else {
      setState(() => _calendarMonth--);
    }
  }

  void _nextMonth() {
    if (_calendarMonth == 12) {
      setState(() { _calendarMonth = 1; _calendarYear++; });
    } else {
      setState(() => _calendarMonth++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          AppTheme.gradientAppBar(widget.student.name, leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  GradientAvatar(name: widget.student.name, size: 64, fontSize: 24),
                  const SizedBox(width: 18),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(widget.student.phone.isEmpty ? AppStrings.get('no_phone') : widget.student.phone, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ]),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 20),
              // Fees summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.04), AppTheme.primaryLight.withValues(alpha: 0.02)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.payments_rounded, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(AppStrings.get('fees'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ]),
                  const SizedBox(height: 16),
                  if (_loadingFees)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: List.generate(12, (i) {
                      final m = i + 1;
                      final status = _feesMap[m] ?? 'unpaid';
                      final isPaid = status == 'paid';
                      return Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isPaid ? AppTheme.success.withValues(alpha: 0.12) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Text(_months[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPaid ? AppTheme.success : Colors.grey.shade500)),
                          const SizedBox(height: 2),
                          Icon(isPaid ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded, size: 14, color: isPaid ? AppTheme.success : Colors.grey.shade400),
                        ]),
                      );
                    })),
                ]),
              ),
              const SizedBox(height: 20),
              // Attendance Calendar
              _buildCalendar(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_month_rounded, color: AppTheme.success, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          if (!_loading)
            Text('${_attendanceHistory.length} days', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
        else ...[
          // Month navigation
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _prevMonth,
              style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: const CircleBorder()),
            ),
            Text('${_months[_calendarMonth - 1]} $_calendarYear',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _nextMonth,
              style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: const CircleBorder()),
            ),
          ]),
          const SizedBox(height: 12),
          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayNames.map((d) => SizedBox(
              width: 32,
              child: Text(d, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            )).toList(),
          ),
          const SizedBox(height: 6),
          // Calendar grid
          ..._buildWeeks(),
          const SizedBox(height: 16),
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(AppTheme.success, AppStrings.get('present')),
            const SizedBox(width: 16),
            _legendDot(AppTheme.danger, AppStrings.get('absent')),
            const SizedBox(width: 16),
            _legendDot(AppTheme.warning, AppStrings.get('holiday')),
          ]),
        ],
      ]),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }

  List<Widget> _buildWeeks() {
    final days = _daysInMonth(_calendarYear, _calendarMonth);
    final start = _firstWeekday(_calendarYear, _calendarMonth);
    final now = DateTime.now();
    final isCurrentMonth = _calendarYear == now.year && _calendarMonth == now.month;
    final today = now.day;

    final List<Widget> weeks = [];
    final dayStrings = <String>[];

    for (int i = 0; i < start; i++) {
      dayStrings.add('');
    }
    for (int d = 1; d <= days; d++) {
      final y = _calendarYear;
      final m = _calendarMonth.toString().padLeft(2, '0');
      final day = d.toString().padLeft(2, '0');
      dayStrings.add('$y-$m-$day');
    }

    for (int w = 0; w < dayStrings.length; w += 7) {
      final weekDays = dayStrings.sublist(w, (w + 7 > dayStrings.length) ? dayStrings.length : w + 7);
      weeks.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            if (i >= weekDays.length || weekDays[i].isEmpty) {
              return const SizedBox(width: 32, height: 32);
            }
            final dateStr = weekDays[i];
            final dayNum = int.tryParse(dateStr.split('-').last) ?? 0;
            final status = _getStatus(dateStr);
            final isToday = isCurrentMonth && dayNum == today;

            Color? dotColor;
            if (status == 'present') dotColor = AppTheme.success;
            else if (status == 'absent') dotColor = AppTheme.danger;
            else if (status == 'holiday') dotColor = AppTheme.warning;

            return SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isToday)
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                          )),
                      if (dotColor != null)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ));
    }
    return weeks;
  }
}
