import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import '../services/absensi_service.dart';
import '../providers/auth_provider.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AbsensiService _absensiService = AbsensiService();

  // Current subject data
  Map<String, dynamic>? _currentSubject;
  bool _isLoadingSubject = true;

  // Camera
  List<CameraDescription>? cameras;
  CameraController? _cameraController;
  bool _isRecognizing = false;
  Timer? _captureTimer;

  // History
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  String _filter = 'month'; // or 'subject'

  // Stored token for async operations
  String? _storedToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _storedToken = Provider.of<AuthProvider>(context, listen: false).token;
    _initializeCameras();
    _loadCurrentSubject();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    _captureTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      // Handle camera initialization error silently
    }
  }

  Future<void> _loadCurrentSubject() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final subject = await _absensiService.getCurrentSubject(
          authProvider.token!,
        );
        if (mounted) {
          setState(() {
            _currentSubject = subject;
            _isLoadingSubject = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSubject = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat mata pelajaran: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final history = await _absensiService.getAttendanceHistory(
          authProvider.token!,
          filter: _filter,
        );
        if (mounted) {
          setState(() {
            _history = history;
            _isLoadingHistory = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $e')));
        }
      }
    }
  }

  Future<void> _startFaceRecognition() async {
    if (cameras == null || cameras!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kamera tidak tersedia')));
      }
      return;
    }

    // Select front camera
    final frontCamera = cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras!.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isRecognizing = true;
        });
      }

      // Start capturing every 2 seconds
      _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        await _captureAndRecognize();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menginisialisasi kamera: $e')),
        );
      }
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      if (_storedToken != null) {
        final result = await _absensiService.recognizeFace(
          _storedToken!,
          File(image.path),
        );
        _stopRecognition();
        if (mounted) {
          _showResultDialog(result);
        }
      }
    } catch (e) {
      // Handle recognition error silently
    }
  }

  void _stopRecognition() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    setState(() {
      _isRecognizing = false;
      _cameraController = null;
    });
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final isSuccess = result['success'] ?? false;
    final message = isSuccess
        ? 'Absensi Berhasil!'
        : 'Wajah Tidak Dikenali. Coba Lagi.';
    final time = result['time'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuccess ? 'Berhasil' : 'Gagal'),
        content: Text('$message\nWaktu: $time'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Absensi'),
            Tab(text: 'Riwayat'),
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
          children: [_buildAbsensiTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildAbsensiTab() {
    if (_isRecognizing) {
      return _buildCameraView();
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _isLoadingSubject
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(99, 102, 241, 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFF6366F1),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentSubject?['subject'] ??
                            'Mata Pelajaran Tidak Diketahui',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentSubject?['teacher'] ?? 'Guru Tidak Diketahui',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(99, 102, 241, 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _startFaceRecognition,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Mulai Absensi Wajah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat kamera...',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
              children: [
                const Icon(Icons.face, color: Color(0xFF6366F1), size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Posisikan wajah Anda di dalam bingkai.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan pencahayaan cukup dan wajah terlihat jelas',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _stopRecognition,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _filter,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF6366F1),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'month',
                  child: Text(
                    '📅 Per Bulan',
                    style: TextStyle(color: Color(0xFF1E293B)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'subject',
                  child: Text(
                    '📚 Per Mata Pelajaran',
                    style: TextStyle(color: Color(0xFF1E293B)),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                    _isLoadingHistory = true;
                  });
                  _loadHistory();
                }
              },
            ),
          ),
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Memuat riwayat...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _history.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat absensi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  item['status'],
                                ).withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getStatusIcon(item['status']),
                                color: _getStatusColor(item['status']),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['subject'] ?? 'Mata Pelajaran',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tanggal: ${item['date'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  item['status'],
                                ).withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(item['status']),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(item['status']),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return const Color(0xFF10B981);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'absent':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'present':
        return 'Hadir';
      case 'late':
        return 'Terlambat';
      case 'absent':
        return 'Alpha';
      default:
        return 'Tidak Diketahui';
    }
  }
}
