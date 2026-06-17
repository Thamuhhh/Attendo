class FeeRecord {
  final String? id;
  final String studentId;
  final int month;
  final int year;
  final String status;
  final double amount;
  final String? paidDate;

  FeeRecord({
    this.id,
    required this.studentId,
    required this.month,
    required this.year,
    this.status = 'unpaid',
    this.amount = 0,
    this.paidDate,
  });

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    return FeeRecord(
      id: json['_id'],
      studentId: json['studentId'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      status: json['status'] ?? 'unpaid',
      amount: (json['amount'] ?? 0).toDouble(),
      paidDate: json['paidDate'],
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'month': month,
    'year': year,
    'status': status,
    'amount': amount,
  };
}

class FeeSummary {
  final int year;
  final List<StudentFeeStatus> summary;

  FeeSummary({required this.year, required this.summary});

  factory FeeSummary.fromJson(Map<String, dynamic> json) {
    return FeeSummary(
      year: json['year'] ?? DateTime.now().year,
      summary: (json['summary'] as List? ?? [])
          .map((e) => StudentFeeStatus.fromJson(e))
          .toList(),
    );
  }
}

class StudentFeeStatus {
  final String id;
  final String name;
  final String phone;
  final int paidMonths;
  final int totalMonths;
  final int dueMonths;
  final List<MonthStatus> records;

  StudentFeeStatus({
    required this.id,
    required this.name,
    this.phone = '',
    required this.paidMonths,
    required this.totalMonths,
    required this.dueMonths,
    required this.records,
  });

  factory StudentFeeStatus.fromJson(Map<String, dynamic> json) {
    return StudentFeeStatus(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      paidMonths: json['paidMonths'] ?? 0,
      totalMonths: json['totalMonths'] ?? 0,
      dueMonths: json['dueMonths'] ?? 0,
      records: (json['records'] as List? ?? [])
          .map((e) => MonthStatus.fromJson(e))
          .toList(),
    );
  }
}

class MonthStatus {
  final int month;
  final String status;
  final double amount;

  MonthStatus({required this.month, required this.status, this.amount = 0});

  factory MonthStatus.fromJson(Map<String, dynamic> json) {
    return MonthStatus(
      month: json['month'] ?? 1,
      status: json['status'] ?? 'unpaid',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}
