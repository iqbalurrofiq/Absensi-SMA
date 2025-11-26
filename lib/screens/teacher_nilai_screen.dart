import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/teacher_service.dart';

class TeacherNilaiScreen extends StatefulWidget {
  const TeacherNilaiScreen({super.key});

  @override
  State<TeacherNilaiScreen> createState() => _TeacherNilaiScreenState();
}

class _TeacherNilaiScreenState extends State<TeacherNilaiScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TeacherService _teacherService = TeacherService();

  // Form controllers for assignment creation
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 7));
  Map<String, dynamic>? _selectedClass;
  dynamic _selectedMaterialFile;

  // Data
  List<dynamic> _classes = [];
  List<dynamic> _assignments = [];
  bool _isLoadingClasses = true;
  bool _isLoadingAssignments = true;
  bool _isCreatingAssignment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _loadAssignments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final assignments = await _teacherService.getTeacherAssignments(
          authProvider.token!,
        );
        if (mounted) {
          setState(() {
            _assignments = assignments;
            _isLoadingAssignments = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingAssignments = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load assignments: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDeadline = pickedDate);
    }
  }

  Future<void> _pickMaterialFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _selectedMaterialFile = result.files.single);
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kelas target')));
      return;
    }

    setState(() => _isCreatingAssignment = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        await _teacherService.createAssignment(
          authProvider.token!,
          _titleController.text,
          _descriptionController.text,
          DateFormat('yyyy-MM-dd').format(_selectedDeadline),
          _selectedClass!['id'],
          materialFile: _selectedMaterialFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dibuat!')),
          );

          // Reset form
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedDeadline = DateTime.now().add(const Duration(days: 7));
            _selectedClass = null;
            _selectedMaterialFile = null;
          });

          // Reload assignments
          _loadAssignments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create assignment: $e')),
          );
        }
      }
    }

    setState(() => _isCreatingAssignment = false);
  }

  void _navigateToGrading(int assignmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignmentGradingScreen(assignmentId: assignmentId),
      ),
    ).then((_) => _loadAssignments()); // Reload when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Nilai'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buat Tugas'),
            Tab(text: 'Penilaian'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [_buildCreateAssignmentTab(), _buildGradingTab()],
        ),
      ),
    );
  }

  Widget _buildCreateAssignmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Tugas Baru',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                hintText: 'Masukkan judul tugas',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul tugas tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Tugas',
                hintText: 'Jelaskan detail tugas yang harus dikerjakan siswa',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi tugas tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Deadline Picker
            InkWell(
              onTap: _selectDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Batas Waktu',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDeadline),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Class Selection
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedClass,
              decoration: const InputDecoration(
                labelText: 'Kelas Target',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _classes.map((classData) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: classData as Map<String, dynamic>,
                  child: Text('${classData['name']} - ${classData['subject']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedClass = value),
              validator: (value) {
                if (value == null) {
                  return 'Pilih kelas target';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Material File Upload
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Materı Pendukung (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedMaterialFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedMaterialFile.name,
                              style: const TextStyle(color: Color(0xFF6366F1)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _selectedMaterialFile = null),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _pickMaterialFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pilih File (PDF/Gambar)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreatingAssignment ? null : _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreatingAssignment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Terbitkan Tugas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingTab() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignments.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada tugas yang dibuat',
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assignment['description'] ?? '',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.class_, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 4),
                  Text(
                    assignment['class_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(assignment['deadline'])),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${assignment['submitted_count'] ?? 0} Sudah Kumpul',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${assignment['total_students'] ?? 0} Total Siswa',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _navigateToGrading(assignment['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Penilaian'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Separate screen for assignment grading details
class AssignmentGradingScreen extends StatefulWidget {
  final int assignmentId;

  const AssignmentGradingScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentGradingScreen> createState() =>
      _AssignmentGradingScreenState();
}

class _AssignmentGradingScreenState extends State<AssignmentGradingScreen> {
  final TeacherService _teacherService = TeacherService();
  Map<String, dynamic>? _assignmentDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignmentDetails();
  }

  Future<void> _loadAssignmentDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final details = await _teacherService.getAssignmentDetails(
          authProvider.token!,
          widget.assignmentId,
        );
        if (mounted) {
          setState(() {
            _assignmentDetails = details;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load assignment details: $e')),
          );
        }
      }
    }
  }

  void _showGradingDialog(Map<String, dynamic> submission) {
    final gradeController = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission['feedback'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nilai ${submission['student_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Nilai (Angka)',
                hintText: '0-100',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Masukkan komentar atau feedback',
              ),
              maxLines: 3,
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
              final grade = int.tryParse(gradeController.text);
              if (grade == null || grade < 0 || grade > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan nilai yang valid (0-100)'),
                  ),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              if (authProvider.token != null) {
                try {
                  await _teacherService.gradeSubmission(
                    authProvider.token!,
                    submission['id'],
                    grade,
                    feedbackController.text,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nilai berhasil disimpan!')),
                    );
                    _loadAssignmentDetails(); // Refresh data
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save grade: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan Nilai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penilaian Tugas'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignmentDetails == null
          ? const Center(child: Text('Failed to load assignment details'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Info
                  Container(
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
                        Text(
                          _assignmentDetails!['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _assignmentDetails!['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submissions List
                  const Text(
                    'Daftar Pengumpulan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submitted Students
                  if (_assignmentDetails!['submitted'] != null &&
                      _assignmentDetails!['submitted'].isNotEmpty)
                    ..._assignmentDetails!['submitted'].map<Widget>((
                      submission,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    submission['student_name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'Dikumpulkan: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(submission['submitted_at']))}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  if (submission['grade'] != null)
                                    Text(
                                      'Nilai: ${submission['grade']}/100',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showGradingDialog(submission),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                submission['grade'] != null
                                    ? 'Edit Nilai'
                                    : 'Beri Nilai',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                  // Not Submitted Students
                  if (_assignmentDetails!['not_submitted'] != null &&
                      _assignmentDetails!['not_submitted'].isNotEmpty)
                    ..._assignmentDetails!['not_submitted'].map<Widget>((
                      student,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.cancel,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  const Text(
                                    'Belum mengumpulkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}
