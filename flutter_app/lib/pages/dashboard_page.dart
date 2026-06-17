import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../models/attendance_record.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  TodayAttendance? _today;
  int _totalStudents = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getTodayAttendance(), ApiService.getStudents()]);
      if (mounted) setState(() { _today = results[0] as TodayAttendance; _totalStudents = (results[1] as List).length; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Error: $e', isError: true); }
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final present = _today?.records.where((r) => r.status == 'present').length ?? 0;
    final absent = _today?.records.where((r) => r.status == 'absent').length ?? 0;

    return BackgroundDecoration(
      child: RefreshIndicator(
        color: AppTheme.primary, onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text('Attendance Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3)),
              ],
            ),
          ),
          Row(children: [
            Expanded(child: _buildStatCard('Total Students', _totalStudents, Icons.people_rounded, AppTheme.primary, 'Enrolled')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Present Today', present, Icons.check_circle_rounded, AppTheme.success, '$absent absent')),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.today_rounded, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            const Text("Today's Attendance", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const Spacer(),
            if (_today != null && _today!.records.isNotEmpty)
              ScaleOnPress(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_today!.records.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    const SizedBox(width: 4),
                    const Text('students', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          if (_loading)
            ...List.generate(4, (_) => const ShimmerCard())
          else if (_today == null || _today!.records.isEmpty)
            _buildEmpty()
          else
            StaggeredList(
              padding: EdgeInsets.zero,
              itemCount: _today!.records.length,
              itemBuilder: (_, i) {
                final r = _today!.records[i];
                final isPresent = r.status == 'present';
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    GradientAvatar(name: r.studentName, size: 44, fontSize: 16),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: isPresent ? AppTheme.success : AppTheme.danger, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(isPresent ? 'Present' : 'Absent', style: TextStyle(fontSize: 12, color: isPresent ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    )),
                    isPresent
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28)
                        : const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 28),
                  ]),
                );
              },
            ),
        ]),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 16),
        AnimatedCounter(value: value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Column(children: [
      const SizedBox(height: 40),
      Icon(Icons.event_busy_rounded, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('No attendance marked today', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text('Go to Attendance tab to mark', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
    ]);
  }
}
