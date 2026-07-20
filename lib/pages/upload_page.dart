import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _service = AttendanceService();
  final _nameController = TextEditingController();
  bool _busy = false;
  String? _status;

  Future<void> _addSingle() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _service.addStudent(name);
      _nameController.clear();
      setState(() => _status = 'Added "$name"');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _bulkUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _busy = true);
    try {
      final content = utf8.decode(result.files.single.bytes!);
      List<String> names;
      if (result.files.single.extension == 'csv') {
        final rows = const CsvToListConverter().convert(content, eol: '\n');
        names = rows
            .map((row) => row.isNotEmpty ? row.first.toString() : '')
            .where((n) => n.isNotEmpty)
            .toList();
      } else {
        names = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      }
      await _service.addStudentsBulk(names);
      setState(() => _status = 'Imported ${names.length} students');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Students')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add one student', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Student name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _addSingle,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Bulk upload', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('CSV (one name per row) or a .txt file with one name per line.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _bulkUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose file'),
            ),
            const SizedBox(height: 16),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}