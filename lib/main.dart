import 'package:flutter/material.dart';
import 'pages/mark_attendance_page.dart';
import 'pages/upload_page.dart';
import 'pages/view_attendance_page.dart';

const _darkRed = Color(0xFF8B0000);

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _darkRed,
          brightness: Brightness.light,
        ).copyWith(primary: _darkRed, onPrimary: Colors.white, surface: Colors.white),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _darkRed.withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(color: selected ? _darkRed : Colors.black54, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? _darkRed : Colors.black54);
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: _darkRed, foregroundColor: Colors.white),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(foregroundColor: _darkRed, side: const BorderSide(color: _darkRed)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade100,
          selectedColor: _darkRed,
          labelStyle: const TextStyle(color: Colors.black87),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: _darkRed),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _darkRed, width: 2),
          ),
        ),
      ),
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
          NavigationDestination(icon: Icon(Icons.upload_file), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'View'),
        ],
      ),
    );
  }
}