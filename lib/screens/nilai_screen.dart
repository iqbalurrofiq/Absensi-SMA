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

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _assignments = assignments;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAssignments = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat tugas: $e')));
    }
  }

  Future<void> _loadGradeSummary(String token) async {
    try {
      final summary = await _nilaiService.getGradeSummary(token);
      setState(() {
        _gradeSummary = summary;
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSummary = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat rangkuman nilai: $e')),
      );
    }
  }

  Future<void> _submitAssignment(int assignmentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.token != null) {
        try {
          await _nilaiService.submitAssignment(
            authProvider.token!,
            assignmentId,
            file,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dikumpulkan!')),
          );
          // Reload assignments to update status
          _loadAssignments(authProvider.token!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengumpulkan tugas: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoadingAssignments || _isLoadingSummary
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Rangkuman Nilai Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Rangkuman Nilai',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rata-rata Semester: ${_gradeSummary?['average'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Daftar Tugas
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mata Pelajaran: ${assignment['subject'] ?? ''}',
                              ),
                              Text(
                                'Batas Waktu: ${assignment['deadline'] ?? ''}',
                              ),
                              Text(
                                'Status: ${assignment['status'] == 'belum_dikumpulkan' ? 'Belum Dikumpulkan' : 'Sudah Dinilai'}',
                              ),
                              const SizedBox(height: 16),
                              if (assignment['status'] == 'belum_dikumpulkan')
                                ElevatedButton(
                                  onPressed: () =>
                                      _submitAssignment(assignment['id']),
                                  child: const Text('Kumpulkan Tugas'),
                                )
                              else if (assignment['status'] == 'sudah_dinilai')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nilai: ${assignment['grade'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Deskripsi: ${assignment['description'] ?? ''}',
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
