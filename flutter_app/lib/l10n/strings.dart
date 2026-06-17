import 'package:flutter/material.dart';

class AppStrings {
  AppStrings._();

  static const _en = {
    'app_name': 'Tuition Attendance',
    'dashboard': 'Dashboard',
    'students': 'Students',
    'attendance': 'Attendance',
    'fees': 'Fees',
    'report': 'Report',
    'search_students': 'Search students...',
    'no_students': 'No students yet',
    'no_matching': 'No matching students',
    'add_student': 'Add Student',
    'edit_student': 'Edit Student',
    'delete_student': 'Delete Student',
    'delete_confirm': 'Remove this student permanently?',
    'present': 'Present',
    'absent': 'Absent',
    'save': 'Save',
    'saving': 'Saving...',
    'cancel': 'Cancel',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'retry': 'Retry',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'no_data': 'No data',
    'today': 'Today',
    'this_week': 'This Week',
    'total_students': 'Total Students',
    'present_today': 'Present Today',
    'absent_today': 'Absent Today',
    'attendance_rate': 'Attendance Rate',
    'mark_attendance': 'Mark Attendance',
    'monthly_fees': 'Monthly Fee Status',
    'paid': 'Paid',
    'unpaid': 'Unpaid',
    'due': 'Due',
    'export_csv': 'Export CSV',
    'student_profile': 'Student Profile',
    'fees_history': 'Fees History',
    'attendance_history': 'Attendance History',
    'settings': 'Settings',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'profile': 'Profile',
  };

  static const _ta = {
    'app_name': 'கல்வி வருகை',
    'dashboard': 'டாஷ்போர்டு',
    'students': 'மாணவர்கள்',
    'attendance': 'வருகைப்பதிவு',
    'fees': 'கட்டணம்',
    'report': 'அறிக்கை',
    'search_students': 'மாணவர்களை தேடுக...',
    'no_students': 'இன்னும் மாணவர்கள் இல்லை',
    'no_matching': 'பொருந்தும் மாணவர்கள் இல்லை',
    'add_student': 'மாணவரை சேர்க்க',
    'edit_student': 'மாணவரை திருத்த',
    'delete_student': 'மாணவரை நீக்க',
    'delete_confirm': 'இந்த மாணவரை நிரந்தரமாக நீக்கவா?',
    'present': 'வந்தார்',
    'absent': 'வரவில்லை',
    'save': 'சேமிக்க',
    'saving': 'சேமிக்கிறது...',
    'cancel': 'ரத்து செய்',
    'logout': 'வெளியேறு',
    'logout_confirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
    'retry': 'மீண்டும் முயற்சி',
    'loading': 'ஏற்றுகிறது...',
    'error': 'பிழை',
    'success': 'வெற்றி',
    'no_data': 'தரவு இல்லை',
    'today': 'இன்று',
    'this_week': 'இந்த வாரம்',
    'total_students': 'மொத்த மாணவர்கள்',
    'present_today': 'இன்று வந்தவர்கள்',
    'absent_today': 'இன்று வராதவர்கள்',
    'attendance_rate': 'வருகை சதவீதம்',
    'mark_attendance': 'வருகைப்பதிவு',
    'monthly_fees': 'மாத கட்டண நிலை',
    'paid': 'செலுத்தப்பட்டது',
    'unpaid': 'செலுத்தப்படவில்லை',
    'due': 'நிலுவை',
    'export_csv': 'CSV ஏற்றுமதி',
    'student_profile': 'மாணவர் விவரம்',
    'fees_history': 'கட்டண வரலாறு',
    'attendance_history': 'வருகை வரலாறு',
    'settings': 'அமைப்புகள்',
    'dark_mode': 'இருண்ட தோற்றம்',
    'language': 'மொழி',
    'profile': 'சுயவிவரம்',
  };

  static Map<String, String> _current = _en;

  static bool isTamil = false;

  static void setLanguage(bool tamil) {
    isTamil = tamil;
    _current = tamil ? _ta : _en;
  }

  static String get(String key) => _current[key] ?? key;
}
