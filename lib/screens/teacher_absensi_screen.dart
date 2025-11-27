import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/teacher_service.dart';

class TeacherAbsensiScreen extends StatefulWidget {
  const TeacherAbsensiScreen({super.key});

  @override
  State<TeacherAbsensiScreen> createState() => _TeacherAbsensiScreenState();
}

class _TeacherAbsensiScreenState extends State<TeacherAbsensiScreen> {
  final TeacherService _teacherService = TeacherService();

  List<dynamic> _classes = [];
  List<dynamic> _attendanceData = [];
  Map<String, dynamic>? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoadingClasses = true;
  bool _isLoadingAttendance = false;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final classes = await _teacherService.getTeacherClasses(
          authProvider.token!,
        );
        if (mounted) {
          setState(() {
            _classes = classes;
            _isLoadingClasses = false;
            // Auto-select first class if available
            if (_classes.isNotEmpty) {
              _selectedClass = _classes[0];
              _loadAttendanceData();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingClasses = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
        }
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedClass == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() => _isLoadingAttendance = true);
      try {
        final attendance = await _teacherService.getClassAttendance(
          authProvider.token!,
          _selectedClass!['id'],
          DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
        if (mounted) {
          setState(() {
            _attendanceData = attendance;
            _isLoadingAttendance = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingAttendance = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load attendance: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateAttendanceStatus(
    int attendanceId,
    String newStatus,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        await _teacherService.updateAttendanceStatus(
          authProvider.token!,
          attendanceId,
          newStatus,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status absensi berhasil diperbarui')),
          );
          _loadAttendanceData(); // Refresh data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update attendance: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
      _loadAttendanceData();
    }
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() => _startDate = pickedDate);
      if (_endDate != null && _endDate!.isBefore(pickedDate)) {
        _endDate = pickedDate;
      }
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() => _endDate = pickedDate);
    }
  }

  void _toggleAdvancedFilters() {
    setState(() => _showAdvancedFilters = !_showAdvancedFilters);
  }

  void _applyDateRangeFilter() {
    if (_startDate != null && _endDate != null) {
      // Here you would implement the date range filtering logic
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filter diterapkan: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
          ),
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedDate = DateTime.now();
    });
    _loadAttendanceData();
  }

  void _sendMessageToStudent(Map<String, dynamic> student) {
    final messageController = TextEditingController();
    final subjectController = TextEditingController(
      text: 'Pemberitahuan Absensi',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kirim Pesan ke ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subjek',
                hintText: 'Judul pesan',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Pesan',
                hintText: 'Tulis pesan untuk siswa',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                // Here you would implement the actual message sending
                // For now, we'll just show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pesan berhasil dikirim ke ${student['name']}',
                    ),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAttendanceData() async {
    if (_attendanceData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    // Create CSV content
    final csvHeader = 'NISN,Nama,Status,Waktu Absen\n';
    final csvRows = _attendanceData
        .map((student) {
          final status = _getStatusText(student['status']);
          final checkInTime = student['check_in_time'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm:ss',
                ).format(DateTime.parse(student['check_in_time']))
              : '';
          return '${student['nisn']},${student['name']},$status,$checkInTime';
        })
        .join('\n');

    final csvContent = csvHeader + csvRows;

    // For now, we'll just show the CSV content in a dialog
    // In a real app, you would save this to a file and share it
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Absensi (CSV)'),
        content: SingleChildScrollView(
          child: Text(
            csvContent,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would implement actual file saving and sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur export akan diimplementasikan'),
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Simpan File'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hadir'),
              leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              onTap: () {
                Navigator.of(context).pop();
                _updateAttendanceStatus(student['attendance_id'], 'present');
              },
            ),
            ListTile(
              title: const Text('Alpha'),
              leading: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
              onTap: () {
                Navigator.of(context).pop();
                _updateAttendanceStatus(student['attendance_id'], 'absent');
              },
            ),
            ListTile(
              title: const Text('Izin'),
              leading: const Icon(Icons.event_busy, color: Color(0xFFF59E0B)),
              onTap: () {
                Navigator.of(context).pop();
                _updateAttendanceStatus(student['attendance_id'], 'excused');
              },
            ),
            ListTile(
              title: const Text('Sakit'),
              leading: const Icon(Icons.sick, color: Color(0xFF8B5CF6)),
              onTap: () {
                Navigator.of(context).pop();
                _updateAttendanceStatus(student['attendance_id'], 'sick');
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return const Color(0xFF10B981);
      case 'absent':
        return const Color(0xFFEF4444);
      case 'excused':
        return const Color(0xFFF59E0B);
      case 'sick':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'present':
        return 'Hadir';
      case 'absent':
        return 'Alpha';
      case 'excused':
        return 'Izin';
      case 'sick':
        return 'Sakit';
      default:
        return 'Belum Absen';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'excused':
        return Icons.event_busy;
      case 'sick':
        return Icons.sick;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Absensi'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleAdvancedFilters,
            icon: Icon(
              _showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            tooltip: 'Filter Lanjutan',
          ),
          IconButton(
            onPressed: _exportAttendanceData,
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Filters Section
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Kelas & Tanggal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Kelas',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _classes.map((classData) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: classData as Map<String, dynamic>,
                              child: Text(
                                '${classData['name']} - ${classData['subject']}',
                              ),
                            );
                          }).toList(),
                          onChanged: _isLoadingClasses
                              ? null
                              : (value) {
                                  setState(() => _selectedClass = value);
                                  _loadAttendanceData();
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Advanced Filters (if enabled)
            if (_showAdvancedFilters)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Rentang Tanggal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Mulai',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_startDate!)
                                    : 'Pilih tanggal',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Akhir',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                    : 'Pilih tanggal',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _endDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyDateRangeFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Terapkan Filter'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset Filter',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Attendance Summary
            if (_selectedClass != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF6366F1).withAlpha(25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Siswa',
                      '${_attendanceData.length}',
                      Icons.people,
                      const Color(0xFF6366F1),
                    ),
                    _buildSummaryItem(
                      'Sudah Absen',
                      '${_attendanceData.where((s) => s['status'] != null).length}',
                      Icons.check_circle,
                      const Color(0xFF10B981),
                    ),
                    _buildSummaryItem(
                      'Belum Absen',
                      '${_attendanceData.where((s) => s['status'] == null).length}',
                      Icons.schedule,
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),

            // Student List
            Expanded(
              child: _isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedClass == null
                  ? const Center(
                      child: Text(
                        'Pilih kelas untuk melihat absensi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : _isLoadingAttendance
                  ? const Center(child: CircularProgressIndicator())
                  : _attendanceData.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data siswa',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _attendanceData.length,
                      itemBuilder: (context, index) {
                        final student = _attendanceData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Profile Photo
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(
                                  0xFF6366F1,
                                ).withAlpha(25),
                                backgroundImage: student['photo'] != null
                                    ? NetworkImage(student['photo'])
                                    : null,
                                child: student['photo'] == null
                                    ? Text(
                                        student['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Student Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'NISN: ${student['nisn'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (student['status'] == 'present' &&
                                        student['check_in_time'] != null)
                                      Text(
                                        'Absen: ${DateFormat('HH:mm').format(DateTime.parse(student['check_in_time']))}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Status and Action
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        student['status'],
                                      ).withAlpha(25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(student['status']),
                                          size: 16,
                                          color: _getStatusColor(
                                            student['status'],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getStatusText(student['status']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                              student['status'],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () =>
                                        _showStatusUpdateDialog(student),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF6366F1),
                                    ),
                                    tooltip: 'Update Status',
                                  ),
                                  if (student['status'] == 'absent')
                                    IconButton(
                                      onPressed: () =>
                                          _sendMessageToStudent(student),
                                      icon: const Icon(
                                        Icons.message,
                                        color: Color(0xFF10B981),
                                      ),
                                      tooltip: 'Kirim Pesan',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
