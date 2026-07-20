import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';

class AttendanceService {
  final _client = Supabase.instance.client;

  Future<List<Student>> fetchStudents() async {
    final data = await _client.from('students').select().order('name');
    return (data as List).map((e) => Student.fromMap(e)).toList();
  }

  Future<void> addStudent(String name) async {
    await _client.from('students').insert({'name': name.trim()});
  }

  Future<void> addStudentsBulk(List<String> names) async {
    final rows = names
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => {'name': n})
        .toList();
    if (rows.isEmpty) return;
    await _client.from('students').insert(rows);
  }

  Future<Set<String>> fetchPresentStudentIds(DateTime date) async {
    final data = await _client
        .from('attendance')
        .select('student_id')
        .eq('date', _formatDate(date));
    return (data as List).map((e) => e['student_id'] as String).toSet();
  }

  Future<void> markPresent(String studentId, DateTime date) async {
    await _client.from('attendance').upsert({
      'student_id': studentId,
      'date': _formatDate(date),
    }, onConflict: 'student_id,date');
  }

  Future<void> markAbsent(String studentId, DateTime date) async {
    await _client
        .from('attendance')
        .delete()
        .eq('student_id', studentId)
        .eq('date', _formatDate(date));
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}