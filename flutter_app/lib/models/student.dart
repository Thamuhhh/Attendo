class Student {
  final String id;
  final String name;
  final String phone;
  final String? createdAt;

  Student({
    required this.id,
    required this.name,
    this.phone = '',
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}
