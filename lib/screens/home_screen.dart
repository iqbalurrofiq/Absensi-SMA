import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // Mock attendance data
  final int totalMeetings = 120;
  final int presentCount = 95;
  final int alphaCount = 8;
  final int izinCount = 12;
  final int sakitCount = 5;

  // Mock schedule data
  final List<Map<String, dynamic>> _schedule = [
    {
      'subject': 'Matematika',
      'teacher': 'Bu Siti',
      'startTime': '07:00',
      'endTime': '08:30',
      'status': 'current',
    },
    {
      'subject': 'Bahasa Indonesia',
      'teacher': 'Pak Ahmad',
      'startTime': '08:30',
      'endTime': '10:00',
      'status': 'next',
    },
    {
      'subject': 'Fisika',
      'teacher': 'Bu Maya',
      'startTime': '10:00',
      'endTime': '11:30',
      'status': 'upcoming',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getAttendanceNotification() {
    // Mock logic - in real app, this would check against schedule
    final hour = _currentTime.hour;
    if (hour >= 7 && hour < 8) {
      return 'Saatnya Absensi Mata Pelajaran Matematika!';
    } else if (hour >= 8 && hour < 10) {
      return 'Saatnya Absensi Mata Pelajaran Bahasa Indonesia!';
    }
    return 'Selamat datang di Smart Presence SMA Unggul 1';
  }

  @override
  Widget build(BuildContext context) {
    final attendancePercentage = (presentCount / totalMeetings) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Presence'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Digital Clock
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(_currentTime),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_currentTime),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getAttendanceNotification(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Attendance Statistics Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistik Kehadiran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Semester Ganjil 2024/2025',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 120,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: presentCount.toDouble(),
                                        title:
                                            '${attendancePercentage.toStringAsFixed(1)}%',
                                        color: Colors.green,
                                        radius: 40,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: alphaCount.toDouble(),
                                        title: '$alphaCount',
                                        color: Colors.red,
                                        radius: 30,
                                      ),
                                      PieChartSectionData(
                                        value: izinCount.toDouble(),
                                        title: '$izinCount',
                                        color: Colors.orange,
                                        radius: 30,
                                      ),
                                      PieChartSectionData(
                                        value: sakitCount.toDouble(),
                                        title: '$sakitCount',
                                        color: Colors.yellow,
                                        radius: 30,
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatItem(
                                'Total Pertemuan',
                                totalMeetings.toString(),
                                Colors.blue,
                              ),
                              _buildStatItem(
                                'Hadir',
                                presentCount.toString(),
                                Colors.green,
                              ),
                              _buildStatItem(
                                'Alpha',
                                alphaCount.toString(),
                                Colors.red,
                              ),
                              _buildStatItem(
                                'Izin',
                                izinCount.toString(),
                                Colors.orange,
                              ),
                              _buildStatItem(
                                'Sakit',
                                sakitCount.toString(),
                                Colors.yellow,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Schedule Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Pelajaran Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._schedule.map((subject) => _buildScheduleItem(subject)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> subject) {
    Color statusColor;
    String statusText;

    switch (subject['status']) {
      case 'current':
        statusColor = Colors.green;
        statusText = 'Sekarang';
        break;
      case 'next':
        statusColor = Colors.blue;
        statusText = 'Selanjutnya';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Akan Datang';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withAlpha(76)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['subject'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subject['teacher'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${subject['startTime']} - ${subject['endTime']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
