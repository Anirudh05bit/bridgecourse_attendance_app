import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/attendance_store.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => MarkAttendancePageState();
}

class MarkAttendancePageState extends State<MarkAttendancePage> {
  final _store = AttendanceStore();
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

  /// Public entry point so other pages (e.g. RootPage) can force a refresh,
  /// for example after a new student is added on the Add Student page.
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _store.fetchStudents();
    final present = await _store.fetchPresentIds(_selectedDate);
    setState(() {
      _allStudents = students;
      _presentIds = present;
      _loading = false;
    });
    _applyFilter();
  }
  Future<void> _confirmNoClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Class?'),
        content: Text(
          'Mark all ${_allStudents.length} students present for '
          '${DateFormat('MMM d, y').format(_selectedDate)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark all present')),
        ],
      ),
    );
    if (confirm != true) return;
    await _store.markAllPresent(_allStudents.map((s) => s.id).toList(), _selectedDate);
    await _load();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allStudents
          : _allStudents.where((s) {
              final nameMatch = s.name.toLowerCase().contains(q);
              final rollMatch = s.rollNumber?.toLowerCase().contains(q) ?? false;
              return nameMatch || rollMatch;
            }).toList();
    });
  }

  Future<void> _toggle(Student s) async {
    final isPresent = _presentIds.contains(s.id);
    setState(() {
      isPresent ? _presentIds.remove(s.id) : _presentIds.add(s.id);
    });
    await _store.setPresent(s.id, _selectedDate, !isPresent);
  }

  List<DateTime> get _dateRange {
    final days = _endDate.difference(_startDate).inDays + 1;
    return List.generate(days, (i) => _startDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _confirmNoClass,
            icon: const Icon(Icons.event_busy, color: Colors.white),
            label: const Text('No Class', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                hintText: 'Search name or roll number',
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
                            subtitle: s.rollNumber != null && s.rollNumber!.isNotEmpty
                                ? Text(s.rollNumber!)
                                : null,
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