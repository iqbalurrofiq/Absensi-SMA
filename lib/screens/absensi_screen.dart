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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Absensi'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAbsensiTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildAbsensiTab() {
    if (_isRecognizing) {
      return _buildCameraView();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingSubject
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        Text(
                          _currentSubject?['subject'] ??
                              'Mata Pelajaran Tidak Diketahui',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentSubject?['teacher'] ?? 'Guru Tidak Diketahui',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startFaceRecognition,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Mulai Absensi Wajah'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(_cameraController!)),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Posisikan wajah Anda di dalam bingkai.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        ElevatedButton(onPressed: _stopRecognition, child: const Text('Batal')),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'month', child: Text('Per Bulan')),
              DropdownMenuItem(
                value: 'subject',
                child: Text('Per Mata Pelajaran'),
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
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return ListTile(
                      title: Text(item['subject'] ?? ''),
                      subtitle: Text(
                        'Tanggal: ${item['date'] ?? ''} | Status: ${item['status'] ?? ''}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
