import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../models/fee_record.dart';
import '../services/api_service.dart';
import '../providers/data_providers.dart';
import '../widgets/widgets.dart';

class FeesPage extends ConsumerStatefulWidget {
  const FeesPage({super.key});

  @override
  ConsumerState<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends ConsumerState<FeesPage> {
  late int _year;
  late int _month;
  bool _saving = false;
  final Map<String, Map<int, String>> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _month = DateTime.now().month;
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
      if (mounted) { AppTheme.showSnack(context, 'Fees updated!'); _pendingChanges.clear(); ref.invalidate(feeSummaryProvider(_year)); }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'Save failed', isError: true);
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
    final summary = ref.watch(feeSummaryProvider(_year)).valueOrNull;
    final student = summary?.summary.where((s) => s.id == studentId).firstOrNull;
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
    final summaryAsync = ref.watch(feeSummaryProvider(_year));
    final d = AppTheme.isDark(context);

    return summaryAsync.when(
      loading: () => BackgroundDecoration(child: Column(children: [
        _buildHeader(context, 0, 0, 0, 0, 0),
        Expanded(child: ListView.builder(itemCount: 5, itemBuilder: (_, __) => const ShimmerCard())),
      ])),
      error: (e, _) => BackgroundDecoration(child: Column(children: [
        _buildHeader(context, 0, 0, 0, 0, 0),
        Expanded(child: ErrorState(message: 'Failed to load fees', onRetry: () => ref.invalidate(feeSummaryProvider(_year)))),
      ])),
      data: (_summary) {
        int thisMonthPaid = 0, thisMonthDue = 0;
        double totalPaidAmount = 0, totalDueAmount = 0;
        if (_summary != null) {
          for (var s in _summary.summary) {
            if (_getDisplayStatus(s.id, _month) == 'paid') thisMonthPaid++; else thisMonthDue++;
            for (final r in s.records) {
              if (r.status == 'paid') totalPaidAmount += r.amount;
              else if (!_isFutureMonth(r.month) && r.status != 'paid') totalDueAmount += r.amount;
            }
          }
        }

        final sorted = _summary == null || _summary.summary.isEmpty ? <StudentFeeStatus>[] : List<StudentFeeStatus>.from(_summary.summary)
          ..sort((a, b) {
            if (a.dueMonths != b.dueMonths) return b.dueMonths.compareTo(a.dueMonths);
            return a.name.compareTo(b.name);
          });

        return BackgroundDecoration(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, _summary?.summary.length ?? 0, thisMonthPaid, thisMonthDue, totalPaidAmount, totalDueAmount),
                  Expanded(child: _buildBody(_summary, sorted, d)),
                ],
              ),
              if (_hasChanges) _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int studentCount, int thisMonthPaid, int thisMonthDue, double totalPaidAmount, double totalDueAmount) {
    final d = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: d ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('fees_management').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.greyShade(context, 500), letterSpacing: 0.8)),
                const SizedBox(height: 3),
                Text(AppStrings.get('monthly_fees'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: d ? Colors.white : AppTheme.textPrimary)),
              ],
            )),
            _yearPicker(),
            const SizedBox(width: 8),
            _monthPicker(),
          ]),
        ),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem(Icons.people_rounded, '$studentCount', AppStrings.get('students'), AppTheme.primary),
            _statItem(Icons.check_circle_rounded, totalPaidAmount > 0 ? '₹${totalPaidAmount.toStringAsFixed(0)}' : '$thisMonthPaid', AppStrings.get('this_month_paid'), AppTheme.success),
            _statItem(Icons.pending_rounded, totalDueAmount > 0 ? '₹${totalDueAmount.toStringAsFixed(0)}' : '$thisMonthDue', AppStrings.get('this_month_due'), AppTheme.danger),
          ]),
        ),
      ]),
    );
  }



  Widget _buildBody(FeeSummary? summary, List<StudentFeeStatus> sorted, bool d) {
    if (summary == null || summary.summary.isEmpty) {
      return const Center(child: EmptyState(
        icon: Icons.payments_outlined,
        title: 'No fee data',
        subtitle: 'Add students to manage fees',
      ));
    }

    return RefreshIndicator(
      color: AppTheme.primary, onRefresh: () async { ref.invalidate(feeSummaryProvider(_year)); },
      child: StaggeredList(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _buildStudentCard(sorted[i]),
      ),
    );
  }

  Widget _buildStudentCard(StudentFeeStatus student) {
    final elapsed = DateTime.now().month;
    final pct = elapsed > 0 ? (student.paidMonths / elapsed * 100).round() : 0;
    final d = AppTheme.isDark(context);
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
              Text(student.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: d ? Colors.white : AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text('${student.paidMonths}/${DateTime.now().month} months paid',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          )),
          AppTheme.percentBadge(context, pct),
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
              final record = student.records.where((r) => r.month == month).firstOrNull;
              final amount = record?.amount ?? 0;
              return GestureDetector(
                onTap: isFuture ? null : () => _toggleFee(student.id, month),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 52,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? AppTheme.greyShade(context, 50)
                        : isPaid
                            ? AppTheme.success.withValues(alpha: d ? 0.25 : 0.15)
                            : overdue
                                ? AppTheme.danger.withValues(alpha: d ? 0.2 : 0.1)
                                : AppTheme.greyShade(context, 100),
                    borderRadius: BorderRadius.circular(12),
                    border: isFuture
                        ? Border.all(color: AppTheme.greyShade(context, 200))
                        : isChanged
                            ? Border.all(color: isPaid ? AppTheme.success : AppTheme.danger, width: 2)
                            : overdue
                                ? Border.all(color: AppTheme.danger.withValues(alpha: 0.3))
                                : isPaid ? Border.all(color: AppTheme.success.withValues(alpha: 0.3))
                                    : Border.all(color: AppTheme.greyShade(context, 200)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_months[month - 1], style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: isFuture ? AppTheme.greyShade(context, 300) : (isPaid ? AppTheme.success : (overdue ? AppTheme.danger : AppTheme.greyShade(context, 500))),
                    )),
                    SizedBox(height: amount > 0 && isPaid ? 1 : 0),
                    Text(amount > 0 ? '₹${amount.toStringAsFixed(0)}' : '—', style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700,
                      color: isPaid ? AppTheme.success : (overdue ? AppTheme.danger : AppTheme.greyShade(context, 400)),
                    )),
                    Icon(
                      isFuture ? Icons.lock_rounded : (isPaid ? Icons.check_circle_rounded : (overdue ? Icons.warning_amber_rounded : Icons.radio_button_unchecked_rounded)),
                      size: 11, color: isFuture ? AppTheme.greyShade(context, 300) : (isPaid ? AppTheme.success : (overdue ? AppTheme.danger : AppTheme.greyShade(context, 400))),
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
                  disabledBackgroundColor: AppTheme.greyShade(context, 300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
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
      decoration: BoxDecoration(color: AppTheme.greyShade(context, 100), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () { setState(() => _year--); },
          child: const Icon(Icons.chevron_left, size: 20, color: AppTheme.textSecondary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$_year', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
        ),
        GestureDetector(
          onTap: () { setState(() => _year++); },
          child: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
        ),
      ]),
    );
  }

  Widget _monthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.greyShade(context, 100), borderRadius: BorderRadius.circular(10)),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDialog<int>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text(AppStrings.get('select_month')),
              children: List.generate(12, (i) {
                final m = i + 1;
                final isFuture = _isFutureMonth(m);
                return SimpleDialogOption(
                  onPressed: isFuture ? null : () => Navigator.pop(ctx, m),
                  child: Text(_months[m - 1], style: TextStyle(
                    fontWeight: m == _month ? FontWeight.w700 : FontWeight.normal,
                    color: isFuture ? AppTheme.greyShade(context, 300) : (m == _month ? AppTheme.primary : null),
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
            child: Text(_months[_month - 1], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
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
      Text(label, style: TextStyle(fontSize: 11, color: AppTheme.greyShade(context, 500))),
    ]);
  }
}
