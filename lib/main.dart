import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/mark_attendance_page.dart';
import 'pages/upload_page.dart';
import 'pages/view_attendance_page.dart';

const supabaseUrl = 'https://vgegfwoxgodrqejxhccg.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZWdmd294Z29kcnFlanhoY2NnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NTEzNzQsImV4cCI6MjEwMDAyNzM3NH0.qjch1M_SIzSm3zWzLURQlz9V6a8dgaLjjWpWpyEx-Ss';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  final _pages = const [
    MarkAttendancePage(),
    UploadPage(),
    ViewAttendancePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Mark'),
          NavigationDestination(icon: Icon(Icons.upload_file), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'View'),
        ],
      ),
    );
  }
}