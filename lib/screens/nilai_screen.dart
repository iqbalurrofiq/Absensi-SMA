import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/nilai_service.dart';
import '../providers/auth_provider.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  final NilaiService _nilaiService = NilaiService();

  List<dynamic> _assignments = [];
  Map<String, dynamic>? _gradeSummary;
  bool _isLoadingAssignments = true;
  bool _isLoadingSummary = true;

  // Stored token for async operations
  String? _storedToken;

  @override
  void initState() {
    super.initState();
    _storedToken = Provider.of<AuthProvider>(context, listen: false).token;
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      await Future.wait([
        _loadAssignments(authProvider.token!),
        _loadGradeSummary(authProvider.token!),
      ]);
    }
  }

  Future<void> _loadAssignments(String token) async {
    try {
      final assignments = await _nilaiService.getAssignments(token);
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAssignments = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat tugas: $e')));
      }
    }
  }

  Future<void> _loadGradeSummary(String token) async {
    try {
      final summary = await _nilaiService.getGradeSummary(token);
      if (mounted) {
        setState(() {
          _gradeSummary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat rangkuman nilai: $e')),
        );
      }
    }
  }

  Future<void> _submitAssignment(int assignmentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      if (_storedToken != null) {
        try {
          await _nilaiService.submitAssignment(
            _storedToken!,
            assignmentId,
            file,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
            );
            // Reload assignments to update status
            _loadAssignments(_storedToken!);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengumpulkan tugas: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoadingAssignments || _isLoadingSummary
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data nilai...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Rangkuman Nilai Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(99, 102, 241, 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.grade,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rangkuman Nilai',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rata-rata Semester: ${_gradeSummary?['average'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Daftar Tugas
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = _assignments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getAssignmentStatusColor(
                                        assignment['status'],
                                      ).withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getAssignmentStatusIcon(
                                        assignment['status'],
                                      ),
                                      color: _getAssignmentStatusColor(
                                        assignment['status'],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignment['title'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Mata Pelajaran: ${assignment['subject'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Batas Waktu: ${assignment['deadline'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getAssignmentStatusColor(
                                    assignment['status'],
                                  ).withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  assignment['status'] == 'belum_dikumpulkan'
                                      ? 'Belum Dikumpulkan'
                                      : 'Sudah Dinilai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getAssignmentStatusColor(
                                      assignment['status'],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (assignment['status'] == 'belum_dikumpulkan')
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _submitAssignment(assignment['id']),
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Kumpulkan Tugas'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                )
                              else if (assignment['status'] == 'sudah_dinilai')
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      16,
                                      185,
                                      129,
                                      0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        16,
                                        185,
                                        129,
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Color(0xFFF59E0B),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Nilai: ${assignment['grade'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Deskripsi: ${assignment['description'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getAssignmentStatusColor(String? status) {
    switch (status) {
      case 'belum_dikumpulkan':
        return const Color(0xFFF59E0B);
      case 'sudah_dinilai':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getAssignmentStatusIcon(String? status) {
    switch (status) {
      case 'belum_dikumpulkan':
        return Icons.assignment;
      case 'sudah_dinilai':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
