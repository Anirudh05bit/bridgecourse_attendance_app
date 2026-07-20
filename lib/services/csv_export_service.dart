import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student.dart';

class CsvExportService {
  static final DateTime startDate = DateTime(2026, 7, 20);
  static final DateTime endDate = DateTime(2026, 8, 13);

  List<DateTime> get dateRange {
    final days = endDate.difference(startDate).inDays + 1;
    return List.generate(days, (i) => startDate.add(Duration(days: i)));
  }

  /// Builds one row per student, one column per day, cell = P or A,
  /// plus trailing Present/Absent totals.
  String buildSummaryCsv(List<Student> students, Map<String, Set<String>> attendanceByDate) {
    final dates = dateRange;
    final buffer = StringBuffer();

    final header = <String>['Name', 'Roll Number'];
    header.addAll(dates.map((d) => DateFormat('MMM d').format(d)));
    header.addAll(['Present Count', 'Absent Count']);
    buffer.writeln(header.map(_escape).join(','));

    for (final s in students) {
      final row = <String>[s.name, s.rollNumber ?? ''];
      var presentCount = 0;
      for (final d in dates) {
        final present = attendanceByDate[_dateKey(d)]?.contains(s.id) ?? false;
        row.add(present ? 'P' : 'A');
        if (present) presentCount++;
      }
      row.add(presentCount.toString());
      row.add((dates.length - presentCount).toString());
      buffer.writeln(row.map(_escape).join(','));
    }

    return buffer.toString();
  }

  Future<void> exportAndShare(String csvContent) async {
    final dir = await getTemporaryDirectory();
    final fileName = 'attendance_summary_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance summary');
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}