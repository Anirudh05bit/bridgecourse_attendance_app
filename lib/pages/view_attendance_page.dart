import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

class ViewAttendancePage extends StatefulWidget {
  const ViewAttendancePage({super.key});

  @override
  State<ViewAttendancePage> createState() => _ViewAttendancePageState();
}

class _ViewAttendancePageState extends State<ViewAttendancePage> {
  final _service = AttendanceService();
  static final _startDate = DateTime(2026, 7, 20);
  static final _endDate = DateTime(2026, 8, 13);

  DateTime? _selectedDate;
  List<Student> _present = [];
  List<Student> _absent = [];
  bool _loading = false;

  List<DateTime> get _dateRange {
    final days = _endDate.difference(_startDate).inDays + 1;
    return List.generate(days, (i) => _startDate.add(Duration(days: i)));
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _loading = true;
    });
    final students = await _service.fetchStudents();
    final presentIds = await _service.fetchPresentStudentIds(date);
    setState(() {
      _present = students.where((s) => presentIds.contains(s.id)).toList();
      _absent = students.where((s) => !presentIds.contains(s.id)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Attendance')),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: _dateRange.length,
              itemBuilder: (context, i) {
                final d = _dateRange[i];
                final selected = _selectedDate != null && _isSameDay(d, _selectedDate!);
                return InkWell(
                  onTap: () => _selectDate(d),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('d\nMMM').format(d),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDate == null
                ? const Center(child: Text('Pick a day above'))
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              DateFormat('EEEE, MMM d, y').format(_selectedDate!),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _SectionHeader(title: 'Present (${_present.length})', color: Colors.green),
                          ..._present.map((s) => ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text(s.name),
                              )),
                          _SectionHeader(title: 'Absent (${_absent.length})', color: Colors.red),
                          ..._absent.map((s) => ListTile(
                                leading: const Icon(Icons.cancel, color: Colors.red),
                                title: Text(s.name),
                              )),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}