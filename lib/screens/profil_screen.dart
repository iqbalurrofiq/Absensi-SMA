import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/profil_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final profile = await _profilService.getProfile(authProvider.token!);
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat profil: $e')));
      }
    }
  }

  Future<void> _editProfilePhoto() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Foto Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (pickedFile != null) {
                  await _uploadPhoto(File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  await _uploadPhoto(File(pickedFile.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(File imageFile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        await _profilService.updateProfilePhoto(authProvider.token!, imageFile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui')),
        );
        _loadProfile(); // Reload profile
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui foto: $e')));
      }
    }
  }

  void _showSettingsDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Fitur ini sedang dalam pengembangan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final shareData = await _profilService.shareProfile(
          authProvider.token!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode profil: ${shareData['code']}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membagikan profil: $e')));
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header Profil
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _profile?['photo'] != null
                                  ? NetworkImage(_profile!['photo'])
                                  : null,
                              child: _profile?['photo'] == null
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: _editProfilePhoto,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profile?['name'] ?? 'Nama Tidak Diketahui',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'NISN: ${_profile?['nisn'] ?? 'Tidak Diketahui'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card 1: Akun & Pengaturan
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text(
                            'Akun & Pengaturan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Text('Privasi'),
                          subtitle: const Text('Pengaturan visibilitas data'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showSettingsDialog('Privasi'),
                        ),
                        ListTile(
                          title: const Text('Keamanan & Izin'),
                          subtitle: const Text(
                            'Ganti sandi, kelola sesi perangkat',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showSettingsDialog('Keamanan & Izin'),
                        ),
                        ListTile(
                          title: const Text('Bagikan Profil'),
                          subtitle: const Text(
                            'Membagikan kode profil atau tautan',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _shareProfile(),
                        ),
                      ],
                    ),
                  ),

                  // Card 2: Dukungan & Tentang
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text(
                            'Dukungan & Tentang',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Text('Pusat Bantuan'),
                          subtitle: const Text(
                            'FAQ dan kontak support sekolah',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showSettingsDialog('Pusat Bantuan'),
                        ),
                        ListTile(
                          title: const Text('Ketentuan dan Kebijakan'),
                          subtitle: const Text(
                            'Term & Condition dan Privacy Policy',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () =>
                              _showSettingsDialog('Ketentuan dan Kebijakan'),
                        ),
                      ],
                    ),
                  ),

                  // Card 3: Sesi Login
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text(
                            'Sesi Login',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Text('Beralih Akun'),
                          subtitle: const Text(
                            'Pilih atau tambahkan akun lain',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showSettingsDialog('Beralih Akun'),
                        ),
                        ListTile(
                          title: const Text('Logout'),
                          subtitle: const Text('Keluar dari sesi aplikasi'),
                          trailing: const Icon(Icons.logout, color: Colors.red),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
