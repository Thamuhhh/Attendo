class AttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final String date;
  final String status;

  AttendanceRecord({
    this.id,
    required this.studentId,
    this.studentName = '',
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'],
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'absent',
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'status': status,
  };
}

class TodayAttendance {
  final String date;
  final List<AttendanceRecord> records;

  TodayAttendance({required this.date, required this.records});

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      date: json['date'] ?? '',
      records: (json['records'] as List? ?? [])
          .map((e) => AttendanceRecord.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyReport {
  final int year;
  final int month;
  final List<StudentReport> report;

  MonthlyReport({required this.year, required this.month, required this.report});

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      report: (json['report'] as List? ?? [])
          .map((e) => StudentReport.fromJson(e))
          .toList(),
    );
  }
}

class StudentReport {
  final String id;
  final String name;
  final String phone;
  final int present;
  final int absent;
  final int total;
  final int percentage;

  StudentReport({
    required this.id,
    required this.name,
    this.phone = '',
    required this.present,
    required this.absent,
    required this.total,
    required this.percentage,
  });

  factory StudentReport.fromJson(Map<String, dynamic> json) {
    return StudentReport(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      total: json['total'] ?? 0,
      percentage: json['percentage'] ?? 0,
    );
  }
}
