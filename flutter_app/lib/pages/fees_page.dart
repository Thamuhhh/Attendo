import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/fee_record.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  late int _year;
  late int _month;
  FeeSummary? _summary;
  bool _loading = true;
  bool _saving = false;
  final Map<String, Map<int, String>> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _month = DateTime.now().month;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService.getFeeSummary(_year);
      if (mounted) {
        setState(() { _summary = s; _loading = false; _pendingChanges.clear(); });
      }
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Error: $e', isError: true); }
    }
  }

  Future<void> _saveAll() async {
    if (_pendingChanges.isEmpty) return;
    setState(() => _saving = true);
    try {
      final records = <Map<String, dynamic>>[];
      _pendingChanges.forEach((studentId, months) {
        months.forEach((month, status) {
          records.add({'studentId': studentId, 'month': month, 'year': _year, 'status': status});
        });
      });
      await ApiService.saveFees(records);
      if (mounted) { AppTheme.showSnack(context, 'Fees updated!'); _pendingChanges.clear(); _load(); }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'Save failed: $e', isError: true);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  bool _isOverdue(int month) {
    final now = DateTime.now();
    return month < now.month && _year <= now.year;
  }

  bool _isFutureMonth(int month) {
    return _year > DateTime.now().year || (_year == DateTime.now().year && month > DateTime.now().month);
  }

  void _toggleFee(String studentId, int month) {
    final current = _pendingChanges[studentId]?[month] ?? _getCurrentStatus(studentId, month);
    final newStatus = current == 'paid' ? 'unpaid' : 'paid';
    setState(() {
      _pendingChanges.putIfAbsent(studentId, () => {});
      _pendingChanges[studentId]![month] = newStatus;
    });
  }

  String _getCurrentStatus(String studentId, int month) {
    final student = _summary?.summary.where((s) => s.id == studentId).firstOrNull;
    final record = student?.records.where((r) => r.month == month).firstOrNull;
    return record?.status ?? 'unpaid';
  }

  String _getDisplayStatus(String studentId, int month) {
    return _pendingChanges[studentId]?[month] ?? _getCurrentStatus(studentId, month);
  }

  bool get _hasChanges => _pendingChanges.isNotEmpty;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    int thisMonthPaid = 0, thisMonthDue = 0;
    if (_summary != null) {
      for (var s in _summary!.summary) {
        if (_getDisplayStatus(s.id, _month) == 'paid') thisMonthPaid++; else thisMonthDue++;
      }
    }

    return BackgroundDecoration(
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(thisMonthPaid, thisMonthDue),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_hasChanges) _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(int thisMonthPaid, int thisMonthDue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF534BAE)]),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FEES MANAGEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.8)),
                SizedBox(height: 3),
                Text('Monthly Fee Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ],
            )),
            _yearPicker(),
            const SizedBox(width: 8),
            _monthPicker(),
          ]),
        ),
        if (_summary != null && _summary!.summary.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem(Icons.people_rounded, '${_summary!.summary.length}', 'Students', AppTheme.primary),
              _statItem(Icons.check_circle_rounded, '$thisMonthPaid', 'This Month Paid', AppTheme.success),
              _statItem(Icons.pending_rounded, '$thisMonthDue', 'This Month Due', AppTheme.danger),
            ]),
          ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(itemCount: 5, itemBuilder: (_, __) => const ShimmerCard());
    }
    if (_summary == null || _summary!.summary.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.payments_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No fee data', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text('Add students to manage fees', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]));
    }

    // Sort: unpaid first, then alphabetically
    final sorted = List<StudentFeeStatus>.from(_summary!.summary)
      ..sort((a, b) {
        if (a.dueMonths != b.dueMonths) return b.dueMonths.compareTo(a.dueMonths);
        return a.name.compareTo(b.name);
      });

    return RefreshIndicator(
      color: AppTheme.primary, onRefresh: _load,
      child: StaggeredList(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _buildStudentCard(sorted[i]),
      ),
    );
  }

  Widget _buildStudentCard(StudentFeeStatus student) {
    final pct = student.totalMonths > 0 ? (student.paidMonths / student.totalMonths * 100).round() : 0;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GradientAvatar(name: student.name, size: 40, fontSize: 15),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text('${student.paidMonths}/${student.totalMonths} months paid',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          )),
          AppTheme.percentBadge(pct),
        ]),
        const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(12, (m) {
              final month = m + 1;
              final status = _getDisplayStatus(student.id, month);
              final isPaid = status == 'paid';
              final isChanged = _pendingChanges[student.id]?.containsKey(month) ?? false;
              final overdue = !isPaid && _isOverdue(month);
              final isFuture = _isFutureMonth(month);
              return GestureDetector(
                onTap: isFuture ? null : () => _toggleFee(student.id, month),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.grey.shade50
                        : isPaid
                            ? AppTheme.success.withValues(alpha: 0.15)
                            : overdue
                                ? AppTheme.danger.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: isFuture
                        ? Border.all(color: Colors.grey.shade200)
                        : isChanged
                            ? Border.all(color: isPaid ? AppTheme.success : AppTheme.danger, width: 2)
                            : overdue
                                ? Border.all(color: AppTheme.danger.withValues(alpha: 0.3))
                                : isPaid ? Border.all(color: AppTheme.success.withValues(alpha: 0.3))
                                    : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_months[month - 1], style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: isFuture ? Colors.grey.shade300 : (isPaid ? AppTheme.success : (overdue ? AppTheme.danger : Colors.grey.shade500)),
                    )),
                    Icon(
                      isFuture ? Icons.lock_rounded : (isPaid ? Icons.check_circle_rounded : (overdue ? Icons.warning_amber_rounded : Icons.radio_button_unchecked_rounded)),
                      size: 14, color: isFuture ? Colors.grey.shade300 : (isPaid ? AppTheme.success : (overdue ? AppTheme.danger : Colors.grey.shade400)),
                    ),
                  ]),
                ),
              );
            }),
          ),
      ]),
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveAll,
              icon: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Fee Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppTheme.accent.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yearPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () { setState(() => _year--); _load(); },
          child: const Icon(Icons.chevron_left, size: 20, color: AppTheme.textSecondary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        GestureDetector(
          onTap: () { setState(() => _year++); _load(); },
          child: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
        ),
      ]),
    );
  }

  Widget _monthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDialog<int>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: const Text('Select Month'),
              children: List.generate(12, (i) {
                final m = i + 1;
                final isFuture = _isFutureMonth(m);
                return SimpleDialogOption(
                  onPressed: isFuture ? null : () => Navigator.pop(ctx, m),
                  child: Text(_months[m - 1], style: TextStyle(
                    fontWeight: m == _month ? FontWeight.w700 : FontWeight.normal,
                    color: isFuture ? Colors.grey.shade300 : (m == _month ? AppTheme.primary : null),
                  )),
                );
              }),
            ),
          );
          if (picked != null && picked != _month) {
            setState(() => _month = picked);
          }
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(_months[_month - 1], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const Icon(Icons.arrow_drop_down, size: 20, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.1)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}
