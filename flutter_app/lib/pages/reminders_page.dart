import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../models/reminder_profile.dart';
import '../services/offline_db.dart';
import '../services/notification_service.dart';
import '../widgets/widgets.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});
  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  List<ReminderProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await OfflineDb.getReminders();
    if (mounted) setState(() { _profiles = p; _loading = false; });
  }

  Future<void> _toggle(ReminderProfile p) async {
    final updated = p.copyWith(enabled: !p.enabled);
    await OfflineDb.updateReminder(updated);
    if (updated.enabled) {
      await NotificationService().scheduleReminder(updated);
    } else {
      await NotificationService().cancelReminder(p.id!);
    }
    _load();
  }

  String _formatTime(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _daysLabel(ReminderProfile p) {
    if (p.everyDay) return 'Every day';
    final dayLabels = AppStrings.isTamil
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final names = <String>[];
    for (int i = 0; i < 7; i++) {
      if (p.hasDay(ReminderProfile.allDays[i])) names.add(dayLabels[i]);
    }
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);

    return Scaffold(
      body: BackgroundDecoration(
        child: Column(
          children: [
            AppTheme.gradientAppBar(
              'Reminders',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: () => _edit(null),
                ),
              ],
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 64,
                            color: d ? Colors.grey.shade600 : Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No reminders yet', style: TextStyle(
                            fontSize: 16, color: d ? Colors.grey.shade400 : Colors.grey.shade500)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Reminder'),
                            onPressed: () => _edit(null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _profiles.length,
                      itemBuilder: (_, i) => _buildCard(_profiles[i], d),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ReminderProfile p, bool d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _edit(p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: d ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                    color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.label, style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15,
                        color: d ? Colors.white : AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(_formatTime(p.hour, p.minute), style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                      const SizedBox(height: 2),
                      Text(_daysLabel(p), style: TextStyle(
                        fontSize: 12,
                        color: d ? Colors.grey.shade400 : AppTheme.textSecondary)),
                      if (p.smartEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            Icon(Icons.auto_awesome, size: 12,
                              color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text('Smart (${p.smartGapDays}d gap)',
                              style: TextStyle(fontSize: 11,
                                color: AppTheme.accent)),
                          ]),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: p.enabled,
                  onChanged: (_) => _toggle(p),
                  activeColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _edit(ReminderProfile? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderForm(
        profile: existing,
        onSaved: () {
          NotificationService().scheduleAllReminders();
          _load();
        },
      ),
    );
  }
}

class _ReminderForm extends StatefulWidget {
  final ReminderProfile? profile;
  final VoidCallback onSaved;
  const _ReminderForm({this.profile, required this.onSaved});

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  late TextEditingController _labelCtrl;
  late TimeOfDay _time;
  late int _daysMask;
  late bool _enabled;
  late bool _smartEnabled;
  late int _smartGapDays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _labelCtrl = TextEditingController(text: p?.label ?? 'Reminder');
    _time = TimeOfDay(hour: p?.hour ?? 18, minute: p?.minute ?? 0);
    _daysMask = p?.daysMask ?? 127;
    _enabled = p?.enabled ?? true;
    _smartEnabled = p?.smartEnabled ?? false;
    _smartGapDays = p?.smartGapDays ?? 2;
  }

  @override
  void dispose() { _labelCtrl.dispose(); super.dispose(); }

  void _toggleDay(int flag) {
    setState(() {
      _daysMask = _daysMask ^ flag;
      if (_daysMask == 0) _daysMask = ReminderProfile.allDays[DateTime.now().weekday % 7];
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = ReminderProfile(
      id: widget.profile?.id,
      label: _labelCtrl.text.trim().isEmpty ? 'Reminder' : _labelCtrl.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      daysMask: _daysMask,
      enabled: _enabled,
      smartEnabled: _smartEnabled,
      smartGapDays: _smartGapDays,
    );
    if (widget.profile == null) {
      await OfflineDb.insertReminder(p);
    } else {
      await OfflineDb.updateReminder(p);
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: d ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              Text(widget.profile == null ? 'New Reminder' : 'Edit Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: d ? Colors.white : AppTheme.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save', style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              ),
            ]),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _labelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                      suffixIcon: const Icon(Icons.access_time_rounded),
                    ),
                    child: Text(_time.format(context)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Repeat on', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: d ? Colors.grey.shade300 : AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: List.generate(7, (i) {
                    final flag = ReminderProfile.allDays[i];
                    final selected = (_daysMask & flag) != 0;
                    return FilterChip(
                      label: Text(ReminderProfile.dayKeys[i].substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.white : null)),
                      selected: selected,
                      selectedColor: AppTheme.primary,
                      checkmarkColor: Colors.white,
                      onSelected: (_) => _toggleDay(flag),
                      backgroundColor: d ? Colors.grey.shade800 : Colors.grey.shade100,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.auto_awesome, size: 16,
                              color: AppTheme.accent),
                            const SizedBox(width: 6),
                            Text('Smart Detection',
                              style: TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: d ? Colors.grey.shade300 : AppTheme.textSecondary)),
                          ]),
                          const SizedBox(height: 4),
                          Text('Notify if attendance missing',
                            style: TextStyle(fontSize: 12,
                              color: d ? Colors.grey.shade500 : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _smartEnabled,
                      onChanged: (v) => setState(() => _smartEnabled = v),
                      activeColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                if (_smartEnabled) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('Gap threshold: ', style: TextStyle(
                      color: d ? Colors.grey.shade300 : AppTheme.textSecondary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: d ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: _smartGapDays > 1
                                ? () => setState(() => _smartGapDays--)
                                : null,
                          ),
                          Text('$_smartGapDays day${_smartGapDays > 1 ? 's' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: _smartGapDays < 14
                                ? () => setState(() => _smartGapDays++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
                if (widget.profile != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await OfflineDb.deleteReminder(widget.profile!.id!);
                        await NotificationService().cancelReminder(widget.profile!.id!);
                        widget.onSaved();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
