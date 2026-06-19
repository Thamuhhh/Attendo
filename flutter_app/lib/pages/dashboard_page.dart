import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../models/attendance_record.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  TodayAttendance? _today;
  int _totalStudents = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getTodayAttendance(), ApiService.getStudents()]);
      if (mounted) setState(() { _today = results[0] as TodayAttendance; _totalStudents = (results[1] as List).length; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Failed to load dashboard', isError: true); }
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _dateStr {
    final d = DateTime.now();
    return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final present = _today?.records.where((r) => r.status == 'present').length ?? 0;
    final absent = _today?.records.where((r) => r.status == 'absent').length ?? 0;

    return BackgroundDecoration(
      child: RefreshIndicator(
        color: AppTheme.primary, onRefresh: load,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 32), children: [
          Text(_greeting, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(_dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 32),
          _buildStatCard(Icons.people_rounded, _totalStudents, 'Total Students', AppTheme.primary),
          const SizedBox(height: 12),
          _buildStatCard(Icons.check_circle_rounded, present, 'Present Today', AppTheme.success),
          if (!_loading && _today != null) ...[
            const SizedBox(height: 32),
            const Text("Today's Attendance", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('${_today!.records.length} students • ${absent} absent', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 14),
            if (_today!.records.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No attendance marked today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ]),
              )
            else
              ..._today!.records.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(children: [
                  GradientAvatar(name: r.studentName, size: 40, fontSize: 15),
                  const SizedBox(width: 14),
                  Expanded(child: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.status == 'present' ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(r.status == 'present' ? 'Present' : 'Absent', style: TextStyle(fontSize: 12, color: r.status == 'present' ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w700)),
                  ),
                ]),
              )),
          ],
          if (_loading)
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(height: 56, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [SizedBox(width: 16),])),
            )),
        ]),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, int value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedCounter(value: value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.2)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }
}
