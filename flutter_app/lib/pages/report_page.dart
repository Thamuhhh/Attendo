import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late int _year;
  late int _month;
  MonthlyReport? _report;
  bool _loading = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _year = n.year;
    _month = n.month;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getMonthlyReport(_year, _month);
      if (mounted) setState(() { _report = r; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Failed to load report', isError: true); }
    }
  }

  void _prev() { setState(() { _month--; if (_month == 0) { _month = 12; _year--; } }); _load(); }
  void _next() { setState(() { _month++; if (_month == 13) { _month = 1; _year++; } }); _load(); }

  bool get _isCurrent {
    final n = DateTime.now();
    return _year == n.year && _month == n.month;
  }

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final totalPresent = _report == null || _report!.report.isEmpty ? 0 : _report!.report.map((r) => r.present).reduce((a, b) => a + b);
    final totalAbsent = _report == null || _report!.report.isEmpty ? 0 : _report!.report.map((r) => r.absent).reduce((a, b) => a + b);
    final totalAll = totalPresent + totalAbsent;
    final avgPct = totalAll > 0 ? (totalPresent / totalAll * 100).round() : 0;

    return BackgroundDecoration(
      child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF534BAE)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AuthService.institutionName ?? 'Attendance Report',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Monthly Attendance Summary',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  )),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ScaleOnPress(
                      onTap: _prev,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                        child: const Icon(Icons.chevron_left_rounded, size: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('${_months[_month - 1]} $_year',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    ),
                    ScaleOnPress(
                      onTap: _isCurrent ? null : _next,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _isCurrent ? Colors.grey.shade100 : Colors.grey.shade200)),
                        child: Icon(Icons.chevron_right_rounded, size: 18, color: _isCurrent ? Colors.grey.shade300 : AppTheme.textPrimary),
                      ),
                    ),
                    const Spacer(),
                    ScaleOnPress(
                      onTap: _exportCsv,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.download_rounded, color: AppTheme.accent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleOnPress(
                      onTap: () => _exportPdf(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: _exporting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.danger, size: 20),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            if (_report != null && _report!.report.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.06), AppTheme.primaryLight.withValues(alpha: 0.03)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _overviewItem(Icons.people_rounded, '${_report!.report.length}', 'Students', AppTheme.primary),
                  _divider(),
                  _overviewItem(Icons.check_circle_rounded, '$totalPresent', 'Present', AppTheme.success),
                  _divider(),
                  _overviewItem(Icons.cancel_rounded, '$totalAbsent', 'Absent', AppTheme.danger),
                  _divider(),
                  _overviewItem(Icons.trending_up_rounded, '$avgPct%', 'Avg', AppTheme.accent),
                ]),
              ),
          ]),
        ),
        Expanded(
          child: _loading
              ? ListView.builder(itemCount: 5, itemBuilder: (_, __) => const ShimmerCard())
              : _report == null || _report!.report.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 20),
                      Text('No Data Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Mark attendance for ${_months[_month - 1]} to generate report',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                    ]))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('STUDENT DETAILS',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
                        ),
                        ..._report!.report.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          final color = r.percentage >= 75 ? AppTheme.success : (r.percentage >= 50 ? AppTheme.warning : AppTheme.danger);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 400 + (i * 80)),
                              curve: Curves.easeOutCubic,
                              builder: (ctx, v, _) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - v)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(children: [
                                        Row(children: [
                                          GradientAvatar(name: r.name, size: 42, fontSize: 16),
                                          const SizedBox(width: 14),
                                          Expanded(child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
                                              const SizedBox(height: 4),
                                              Row(children: [
                                                _statBadge('${r.present}', 'Present', AppTheme.success),
                                                const SizedBox(width: 8),
                                                _statBadge('${r.absent}', 'Absent', AppTheme.danger),
                                                const SizedBox(width: 8),
                                                _statBadge('${r.total}', 'Total', Colors.grey),
                                              ]),
                                            ],
                                          )),
                                          Container(
                                            width: 56, height: 56,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: color.withValues(alpha: 0.2)),
                                            ),
                                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              Text('${r.percentage}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
                                              Text('Rate', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
                                            ]),
                                          ),
                                        ]),
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: SizedBox(
                                            height: 8,
                                            child: Row(children: [
                                              if (r.present > 0)
                                                Expanded(flex: r.present, child: Container(color: AppTheme.success)),
                                              if (r.absent > 0)
                                                Expanded(flex: r.absent, child: Container(color: AppTheme.danger)),
                                            ]),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Text('Present', style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          Text('Absent', style: TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w600)),
                                        ]),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
        ),
      ]),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }

  Widget _overviewItem(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.1)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ]),
    );
  }

  void _exportCsv() async {
    if (_report == null || _report!.report.isEmpty) { AppTheme.showSnack(context, 'No data to export', isError: true); return; }
    try {
      final buffer = StringBuffer();
      buffer.writeln('Name,Phone,Present,Absent,Total,Percentage');
      for (final r in _report!.report) {
        buffer.writeln('"${r.name}","${r.phone}",${r.present},${r.absent},${r.total},${r.percentage}');
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/report_${_year}_${_month.toString().padLeft(2, '0')}.csv');
      await file.writeAsString(buffer.toString());
      if (mounted) {
        AppTheme.showSnack(context, 'CSV saved to ${file.path}');
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'Export failed', isError: true);
    }
  }

  Future<void> _exportPdf() async {
    if (_report == null || _report!.report.isEmpty) { AppTheme.showSnack(context, 'No data to export', isError: true); return; }
    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text('Attendance Report: ${_months[_month - 1]} $_year',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Paragraph(text: 'Generated on ${DateTime.now().toLocal().toString().split('.').first}'),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headers: ['#', 'Name', 'Phone', 'Present', 'Absent', 'Total', 'Percentage'],
              data: List.generate(_report!.report.length, (i) {
                final r = _report!.report[i];
                return [
                  '${i + 1}',
                  r.name,
                  r.phone,
                  '${r.present}',
                  '${r.absent}',
                  '${r.total}',
                  '${r.percentage}%',
                ];
              }),
            ),
            pw.SizedBox(height: 32),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('Total Students', '${_report!.report.length}'),
                _pdfStat('Total Present', '${_report!.report.fold(0, (s, r) => s + r.present)}'),
                _pdfStat('Total Absent', '${_report!.report.fold(0, (s, r) => s + r.absent)}'),
              ],
            ),
          ],
        ),
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/report_${_year}_${_month.toString().padLeft(2, '0')}.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        AppTheme.showSnack(context, 'PDF saved to ${file.path}');
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'PDF export failed', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
    ]);
  }

}
