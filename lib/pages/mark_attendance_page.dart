import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final _service = AttendanceService();
  final _searchController = TextEditingController();

  static final _startDate = DateTime(2026, 7, 20);
  static final _endDate = DateTime(2026, 8, 13);

  late DateTime _selectedDate;
  List<Student> _allStudents = [];
  List<Student> _filtered = [];
  Set<String> _presentIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    _selectedDate = todayOnly.isBefore(_startDate)
        ? _startDate
        : (todayOnly.isAfter(_endDate) ? _endDate : todayOnly);
    _searchController.addListener(_applyFilter);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _service.fetchStudents();
    final present = await _service.fetchPresentStudentIds(_selectedDate);
    setState(() {
      _allStudents = students;
      _presentIds = present;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allStudents
          : _allStudents.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _toggle(Student s) async {
    final isPresent = _presentIds.contains(s.id);
    setState(() {
      isPresent ? _presentIds.remove(s.id) : _presentIds.add(s.id);
    });
    try {
      if (isPresent) {
        await _service.markAbsent(s.id, _selectedDate);
      } else {
        await _service.markPresent(s.id, _selectedDate);
      }
    } catch (e) {
      setState(() {
        isPresent ? _presentIds.add(s.id) : _presentIds.remove(s.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  List<DateTime> get _dateRange {
    final days = _endDate.difference(_startDate).inDays + 1;
    return List.generate(days, (i) => _startDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _dateRange.length,
              itemBuilder: (context, i) {
                final d = _dateRange[i];
                final selected = _isSameDay(d, _selectedDate);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(DateFormat('MMM d').format(d)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedDate = d);
                      _load();
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search student name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final s = _filtered[i];
                          final present = _presentIds.contains(s.id);
                          return ListTile(
                            title: Text(s.name),
                            trailing: FilledButton.tonalIcon(
                              onPressed: () => _toggle(s),
                              icon: Icon(present ? Icons.check_circle : Icons.circle_outlined),
                              label: Text(present ? 'Present' : 'Mark present'),
                              style: present
                                  ? FilledButton.styleFrom(
                                      backgroundColor: Colors.green.shade100,
                                      foregroundColor: Colors.green.shade800,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}