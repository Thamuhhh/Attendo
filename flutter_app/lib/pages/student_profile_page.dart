import 'package:flutter/material.dart';
import '../theme.dart';
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
  Map<int, String> _feesMap = {};
  bool _loadingFees = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getAttendanceByDate(''),
        ApiService.getFeeRecords(widget.student.id, DateTime.now().year),
      ]);
      if (mounted) {
        final att = results[0] as List;
        final fees = results[1] as List;
        setState(() {
          _attendanceHistory = att.where((a) => a.studentId == widget.student.id).map((a) => {'date': a.date, 'status': a.status}).toList();
          for (final f in fees) { _feesMap[f.month] = f.status; }
          _loading = false;
          _loadingFees = false;
        });
      }
    } catch (_) { if (mounted) setState(() { _loading = false; _loadingFees = false; }); }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

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
                        Text(widget.student.phone.isEmpty ? 'No phone' : widget.student.phone, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
                    const Text('Fees - This Year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
              // Attendance history
              Container(
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
                      child: const Icon(Icons.history_rounded, color: AppTheme.success, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ]),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_attendanceHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('No attendance records', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
                    )
                  else
                    ...List.generate(_attendanceHistory.length.clamp(0, 20), (i) {
                      final a = _attendanceHistory[i];
                      final isPresent = a['status'] == 'present';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: isPresent ? AppTheme.success : AppTheme.danger),
                          const SizedBox(width: 10),
                          Text(a['date'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPresent ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(isPresent ? 'Present' : 'Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPresent ? AppTheme.success : AppTheme.danger)),
                          ),
                        ]),
                      );
                    }),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
