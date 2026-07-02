import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import 'student_profile_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Student> _students = [];
  List<Student> _filtered = [];
  bool _loading = true;
  bool _isSearching = false;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() { _filter(); setState(() => _isSearching = _searchCtrl.text.isNotEmpty); });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await ApiService.getStudents();
      if (mounted) setState(() { _students = s; _filter(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = AppStrings.get('failed_to_load'); });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filtered = _students.where((s) => s.name.toLowerCase().contains(q)).toList());
  }

  void _showForm({Student? student}) {
    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final isEdit = student != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppTheme.greyShade(context, 300), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEdit ? [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.8)] : [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: (isEdit ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Text(isEdit ? AppStrings.get('edit_student') : AppStrings.get('add_student'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.isDark(context) ? Colors.white : AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 24),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.get('full_name'), prefixIcon: const Icon(Icons.person_outline)), autofocus: true),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: AppStrings.get('phone_number'), prefixIcon: const Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    if (isEdit) { await ApiService.updateStudent(student.id, nameCtrl.text.trim(), phoneCtrl.text.trim()); }
                    else { await ApiService.addStudent(nameCtrl.text.trim(), phoneCtrl.text.trim()); }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    AppTheme.showSnack(context, isEdit ? AppStrings.get('update_success') : AppStrings.get('add_success'));
                  } catch (e) {
                    if (ctx.mounted) { Navigator.pop(ctx); AppTheme.showSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true); }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit ? AppTheme.accent : AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(isEdit ? AppStrings.get('edit_student') : AppStrings.get('add_student'), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(Student student) async {
    final confirmed = await AppTheme.showConfirm(
      context, AppStrings.get('delete_student'),
      AppStrings.get('delete_confirm'),
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteStudent(student.id);
      _load();
      if (mounted) AppTheme.showToast(context, AppStrings.get('delete_success'));
    } catch (e) {
      if (mounted) AppTheme.showToast(context, AppStrings.get('delete_failed'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return BackgroundDecoration(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: AppStrings.get('search_students'),
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.greyShade(context, 400)),
              hintStyle: TextStyle(color: AppTheme.greyShade(context, 400)),
              suffixIcon: _isSearching ? IconButton(
                icon: Icon(Icons.clear_rounded, color: AppTheme.greyShade(context, 400), size: 20),
                onPressed: () { _searchCtrl.clear(); },
              ) : null,
            ),
          )),
          const SizedBox(width: 12),
          ScaleOnPress(
            onTap: () => _showForm(),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ]),
      ),
      if (_filtered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(children: [
            Text('${_filtered.length} ${AppStrings.get('students').toLowerCase()}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
        ),
      Expanded(
        child: _loading
            ? ListView.builder(itemCount: 6, itemBuilder: (_, __) => const ShimmerCard())
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: _searchCtrl.text.isNotEmpty ? Icons.person_search_rounded : Icons.people_outlined,
                        title: _searchCtrl.text.isNotEmpty ? AppStrings.get('no_matching') : AppStrings.get('no_students'),
                        subtitle: _searchCtrl.text.isNotEmpty ? AppStrings.get('search_by_name') : AppStrings.get('tap_to_add'),
                        actionLabel: _searchCtrl.text.isEmpty ? AppStrings.get('add_student') : null,
                        onAction: _searchCtrl.text.isEmpty ? () => _showForm() : null,
                      )
                    : RefreshIndicator(
                    color: AppTheme.primary, onRefresh: _load,
                    child: StaggeredList(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return Dismissible(
                          key: ValueKey(s.id),
                          direction: DismissDirection.endToStart,
                           confirmDismiss: (_) async => await AppTheme.showConfirm(context, AppStrings.get('delete_student'), AppStrings.get('delete_confirm')),
                           onDismissed: (_) async {
                             try {
                               await ApiService.deleteStudent(s.id);
                               if (mounted) AppTheme.showToast(context, AppStrings.get('delete_success'));
                               _load();
                             } catch (e) {
                               if (mounted) AppTheme.showToast(context, AppStrings.get('delete_failed'), isError: true);
                               _load();
                             }
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.danger, AppTheme.danger], begin: Alignment.centerLeft, end: Alignment.centerRight),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                          ),
                          child: GlassCard(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfilePage(student: s))),
                            onLongPress: () => _confirmDelete(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                Hero(tag: 'student_${s.id}', child: GradientAvatar(name: s.name, size: 44, fontSize: 16)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: d ? Colors.white : AppTheme.textPrimary)),
                                    if (s.phone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Icon(Icons.phone_rounded, size: 12, color: AppTheme.greyShade(context, 400)),
                                        const SizedBox(width: 4),
                                        Text(s.phone, style: TextStyle(fontSize: 12, color: AppTheme.greyShade(context, 500))),
                                      ]),
                                    ],
                                  ],
                                )),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  ScaleOnPress(
                                    onTap: () => _showForm(student: s),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: d ? 0.3 : 0.1), AppTheme.primary.withValues(alpha: d ? 0.2 : 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ScaleOnPress(
                                    onTap: () => _confirmDelete(s),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [AppTheme.danger.withValues(alpha: d ? 0.3 : 0.1), AppTheme.danger.withValues(alpha: d ? 0.2 : 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                    ),
                                  ),
                                ]),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                    ),
                  ),
      ),
      ]));
    }
  }
