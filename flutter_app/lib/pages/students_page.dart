import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
    setState(() => _loading = true);
    try {
      final s = await ApiService.getStudents();
      if (mounted) setState(() { _students = s; _filter(); _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); AppTheme.showSnack(context, 'Failed to load', isError: true); }
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isEdit ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: isEdit ? AppTheme.accent : AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Text(isEdit ? 'Edit Student' : 'Add Student', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 24),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), autofocus: true),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    if (isEdit) { await ApiService.updateStudent(student!.id, nameCtrl.text.trim(), phoneCtrl.text.trim()); }
                    else { await ApiService.addStudent(nameCtrl.text.trim(), phoneCtrl.text.trim()); }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    AppTheme.showSnack(context, isEdit ? 'Updated successfully!' : 'Student added!');
                  } catch (e) {
                    if (ctx.mounted) { Navigator.pop(ctx); AppTheme.showSnack(context, '$e', isError: true); }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit ? AppTheme.accent : AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? 'Update Student' : 'Add Student', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(Student student) async {
    final confirmed = await AppTheme.showConfirm(
      context, 'Delete Student',
      'Remove "${student.name}" permanently?\nAll attendance records will also be deleted.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteStudent(student.id);
      _load();
      if (mounted) AppTheme.showToast(context, 'Deleted successfully');
    } catch (e) {
      if (mounted) AppTheme.showToast(context, 'Delete failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixIcon: _isSearching ? IconButton(
                icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400, size: 20),
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
                gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFF00E5BF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
            Text('${_filtered.length} student${_filtered.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
        ),
      Expanded(
        child: _loading
            ? ListView.builder(itemCount: 6, itemBuilder: (_, __) => const ShimmerCard())
            : _filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_searchCtrl.text.isNotEmpty ? Icons.person_search_rounded : Icons.people_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(_searchCtrl.text.isNotEmpty ? 'No matching students' : 'No students yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(_searchCtrl.text.isNotEmpty ? 'Try a different search' : 'Tap + to add students',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    const SizedBox(height: 12),
                    if (_searchCtrl.text.isEmpty)
                      Text('Server resets on restart — data is temporary', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                  ]))
                : RefreshIndicator(
                    color: AppTheme.primary, onRefresh: _load,
                    child: StaggeredList(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onLongPress: () => _confirmDelete(s),
                            child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfilePage(student: s))),
                            onLongPress: () => _confirmDelete(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [
                                GradientAvatar(name: s.name, size: 44, fontSize: 16),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                    if (s.phone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text(s.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ]),
                                    ],
                                  ],
                                )),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  ScaleOnPress(
                                    onTap: () => _showForm(student: s),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ScaleOnPress(
                                    onTap: () => _confirmDelete(s),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
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
    ]);
  }
}
