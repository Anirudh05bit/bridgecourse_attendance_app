import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../data/students_data.dart';

/// Stores everything on-device using SharedPreferences.
/// - Present list per date (everyone not listed is absent by default)
/// - Any manually-added students, merged with the hardcoded registeredStudents list
class AttendanceStore {
  static const _attendanceKey = 'attendance_by_date';
  static const _extraStudentsKey = 'extra_students';
  /// All present-lists for every date that has any data, keyed by yyyy-MM-dd.
  Future<Map<String, Set<String>>> fetchAllAttendance() async {
    final data = await _loadAttendance();
    return data.map((k, v) => MapEntry(k, v.toSet()));
  }

  /// Marks every given student ID present for [date] in one write — used for "No Class" days.
  Future<void> markAllPresent(List<String> studentIds, DateTime date) async {
    final data = await _loadAttendance();
    data[_dateKey(date)] = studentIds;
    await _saveAttendance(data);
  }

  Future<List<Student>> fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_extraStudentsKey);
    final extras = <Student>[];
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        extras.add(Student(
          id: e['id'] as String,
          name: e['name'] as String,
          rollNumber: e['rollNumber'] as String?,
        ));
      }
    }
    final all = [...registeredStudents, ...extras];
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return all;
  }

  Future<void> addStudent(String name, {String? rollNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_extraStudentsKey);
    final list = raw != null ? (jsonDecode(raw) as List) : [];
    list.add({
      'id': 'extra_${DateTime.now().microsecondsSinceEpoch}',
      'name': name.trim(),
      'rollNumber': (rollNumber != null && rollNumber.trim().isNotEmpty) ? rollNumber.trim() : null,
    });
    await prefs.setString(_extraStudentsKey, jsonEncode(list));
  }

  Future<Set<String>> fetchPresentIds(DateTime date) async {
    final data = await _loadAttendance();
    return (data[_dateKey(date)] ?? []).toSet();
  }

  Future<void> setPresent(String studentId, DateTime date, bool present) async {
    final data = await _loadAttendance();
    final key = _dateKey(date);
    final ids = (data[key] ?? []).toSet();
    present ? ids.add(studentId) : ids.remove(studentId);
    data[key] = ids.toList();
    await _saveAttendance(data);
  }

  Future<Map<String, List<String>>> _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attendanceKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  Future<void> _saveAttendance(Map<String, List<String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attendanceKey, jsonEncode(data));
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}