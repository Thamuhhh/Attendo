class ReminderProfile {
  final int? id;
  final String label;
  final int hour;
  final int minute;
  final int daysMask;
  final bool enabled;
  final bool smartEnabled;
  final int smartGapDays;

  const ReminderProfile({
    this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.daysMask = 127,
    this.enabled = true,
    this.smartEnabled = false,
    this.smartGapDays = 2,
  });

  static const int sun = 1;
  static const int mon = 2;
  static const int tue = 4;
  static const int wed = 8;
  static const int thu = 16;
  static const int fri = 32;
  static const int sat = 64;

  static const List<int> allDays = [sun, mon, tue, wed, thu, fri, sat];
  static const List<String> dayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  bool hasDay(int flag) => (daysMask & flag) != 0;

  int dayCount() => allDays.fold(0, (sum, d) => sum + (hasDay(d) ? 1 : 0));

  bool get everyDay => daysMask == 127;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'label': label,
    'hour': hour,
    'minute': minute,
    'days_mask': daysMask,
    'enabled': enabled ? 1 : 0,
    'smart_enabled': smartEnabled ? 1 : 0,
    'smart_gap_days': smartGapDays,
  };

  factory ReminderProfile.fromMap(Map<String, dynamic> m) => ReminderProfile(
    id: m['id'] as int?,
    label: m['label'] as String? ?? 'Reminder',
    hour: m['hour'] as int? ?? 18,
    minute: m['minute'] as int? ?? 0,
    daysMask: m['days_mask'] as int? ?? 127,
    enabled: (m['enabled'] as int? ?? 1) == 1,
    smartEnabled: (m['smart_enabled'] as int? ?? 0) == 1,
    smartGapDays: m['smart_gap_days'] as int? ?? 2,
  );

  ReminderProfile copyWith({
    int? id,
    String? label,
    int? hour,
    int? minute,
    int? daysMask,
    bool? enabled,
    bool? smartEnabled,
    int? smartGapDays,
  }) => ReminderProfile(
    id: id ?? this.id,
    label: label ?? this.label,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    daysMask: daysMask ?? this.daysMask,
    enabled: enabled ?? this.enabled,
    smartEnabled: smartEnabled ?? this.smartEnabled,
    smartGapDays: smartGapDays ?? this.smartGapDays,
  );
}
