import 'package:flutter/material.dart';
import 'teacher_home_screen.dart';
import 'teacher_absensi_screen.dart';
import 'teacher_nilai_screen.dart';
import 'teacher_profil_screen.dart';

class TeacherMainNavigation extends StatefulWidget {
  const TeacherMainNavigation({super.key});

  @override
  State<TeacherMainNavigation> createState() => _TeacherMainNavigationState();
}

class _TeacherMainNavigationState extends State<TeacherMainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TeacherHomeScreen(),
    const TeacherAbsensiScreen(),
    const TeacherNilaiScreen(),
    const TeacherProfilScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    const BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt),
      label: 'Absensi',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.grade), label: 'Nilai'),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
        backgroundColor: const Color(0xFF6366F1),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
