import 'package:flutter/material.dart';
import '../services/attendance_store.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _store = AttendanceStore();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  bool _busy = false;
  String? _status;

  Future<void> _addSingle() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _store.addStudent(name, rollNumber: _rollController.text.trim());
      _nameController.clear();
      _rollController.clear();
      setState(() => _status = 'Added "$name"');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add one student', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Student name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rollController,
              decoration: const InputDecoration(hintText: 'Roll number (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _addSingle,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add student'),
            ),
            const SizedBox(height: 16),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}