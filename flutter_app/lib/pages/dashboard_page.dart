import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/strings.dart';
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
  String? _error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([ApiService.getTodayAttendance(), ApiService.getStudents()]);
      if (mounted) setState(() { _today = results[0] as TodayAttendance; _totalStudents = (results[1] as List).length; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = AppStrings.get('failed_to_load'); });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.get('good_morning');
    if (h < 17) return AppStrings.get('good_afternoon');
    return AppStrings.get('good_evening');
  }

  String get _dateStr {
    final d = DateTime.now();
    return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final present = _today?.records.where((r) => r.status == 'present').length ?? 0;
    final d = AppTheme.isDark(context);

    if (_error != null) {
      return BackgroundDecoration(
        child: Center(
          child: ErrorState(message: _error!, onRetry: load),
        ),
      );
    }

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
                    Text(AppStrings.get('attendance'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.greyShade(context, 400)),
                      const SizedBox(width: 6),
                      Text(_dateStr, style: TextStyle(fontSize: 13, color: AppTheme.greyShade(context, 500), fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: _buildStatCard(Icons.people_rounded, _totalStudents, AppStrings.get('total_students'), AppTheme.primary, const Color(0xFF6C63FF))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(Icons.check_circle_rounded, present, AppStrings.get('present_today'), AppTheme.success, const Color(0xFF10B981))),
          ]),
          if (!_loading && _today != null) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Text(AppStrings.get('todays_attendance'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: d ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_today!.records.length} students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_today!.records.isEmpty)
              EmptyState(
                icon: Icons.event_busy_rounded,
                title: AppStrings.get('no_attendance_today'),
              )
            else
              ..._today!.records.map((r) => GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  GradientAvatar(name: r.studentName, size: 40, fontSize: 15),
                  const SizedBox(width: 14),
                  Expanded(child: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: r.status == 'present' ? AppTheme.success.withValues(alpha: d ? 0.2 : 0.1) : AppTheme.danger.withValues(alpha: d ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: r.status == 'present' ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(r.status == 'present' ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: r.status == 'present' ? AppTheme.success : AppTheme.danger),
                      const SizedBox(width: 4),
                      Text(r.status == 'present' ? AppStrings.get('present') : AppStrings.get('absent'), style: TextStyle(fontSize: 12, color: r.status == 'present' ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              )),
          ],
          if (_loading)
            ...List.generate(2, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(),
            )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, int value, String label, Color color, Color gradientColor) {
    final d = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: d ? 0.2 : 0.08),
            color.withValues(alpha: d ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: d ? 0.2 : 0.1)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: d ? 0.08 : 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: d ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        AnimatedCounter(value: value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: AppTheme.greyShade(context, 500))),
      ]),
    );
  }
}
