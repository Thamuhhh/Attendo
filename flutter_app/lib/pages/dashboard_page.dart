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

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TodayAttendance? _today;
  int _totalStudents = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _weeklyLoading = true;

  @override
  void initState() { super.initState(); _load(); _loadWeekly(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getTodayAttendance(), ApiService.getStudents()]);
      if (mounted) setState(() { _today = results[0] as TodayAttendance; _totalStudents = (results[1] as List).length; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Error: $e', isError: true); }
    }
  }

  Future<void> _loadWeekly() async {
    try {
      final data = await ApiService.getWeeklyAttendance();
      if (mounted) setState(() { _weeklyData = data; _weeklyLoading = false; });
    } catch (_) { if (mounted) setState(() => _weeklyLoading = false); }
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
    super.build(context);
    final present = _today?.records.where((r) => r.status == 'present').length ?? 0;
    final absent = _today?.records.where((r) => r.status == 'absent').length ?? 0;
    final total = _today?.records.length ?? 0;
    final percent = total > 0 ? (present / total * 100).round() : 0;

    return BackgroundDecoration(
      child: RefreshIndicator(
        color: AppTheme.primary, onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
          // Greeting + Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    const Text('Attendance Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.primary.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(_dateStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary.withValues(alpha: 0.8))),
                      ]),
                    ),
                  ],
                ),
              ),
              // Attendance ring
              if (!_loading && total > 0)
                SizedBox(
                  width: 72, height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressWidget(percent: percent, size: 72, strokeWidth: 6),
                      Text('$percent%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: percent >= 75 ? AppTheme.success : (percent >= 50 ? AppTheme.warning : AppTheme.danger))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Stat cards
          Row(children: [
            Expanded(child: _buildStatCard('Total Students', _totalStudents, Icons.people_rounded, AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Present Today', present, Icons.check_circle_rounded, AppTheme.success)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildStatCard('Absent Today', absent, Icons.cancel_rounded, AppTheme.danger)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Attendance Rate', percent, Icons.trending_up_rounded, percent >= 75 ? AppTheme.success : (percent >= 50 ? AppTheme.warning : AppTheme.danger), '$percent%')),
          ]),
            const SizedBox(height: 20),
          // Weekly chart
          if (!_weeklyLoading && _weeklyData.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('This Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ]),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_weeklyData.length, (i) {
                    final d = _weeklyData[i];
                    final total = (d['total'] as int?) ?? 0;
                    final present = (d['present'] as int?) ?? 0;
                    final maxVal = _weeklyData.fold<int>(0, (a, b) => a > ((b['total'] as int?) ?? 0) ? a : ((b['total'] as int?) ?? 0));
                    final height = maxVal > 0 ? (total / maxVal) * 100 : 0.0;
                    final pct = total > 0 ? (present / total * 100).round() : 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(children: [
                          Text('$present', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            height: 60,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 20,
                              height: (height / 100) * 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: pct >= 75
                                      ? [AppTheme.primaryLight, AppTheme.primary]
                                      : pct >= 50
                                          ? [AppTheme.warning, AppTheme.accent]
                                          : [AppTheme.danger, AppTheme.warning],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(d['day'] ?? '', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  }),
                ),
              ]),
            ),
          const SizedBox(height: 28),
          // Today's attendance header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.today_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text("Today's Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const Spacer(),
            if (!_loading && _today != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_today!.records.length} students', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
          ]),
          const SizedBox(height: 14),
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
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPresent ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(isPresent ? 'Present' : 'Absent', style: TextStyle(fontSize: 11, color: isPresent ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ],
                    )),
                    isPresent
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
                          )
                        : Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 24),
                          ),
                  ]),
                );
              },
            ),
        ]),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, [String? sub]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.06), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            if (sub != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8))),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedCounter(value: value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No attendance marked today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text('Mark attendance in the Attendance tab', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        Text('Server resets on restart — data is temporary', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
