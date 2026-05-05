import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../utils/app_theme.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  File? _image;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar('Aktifkan layanan lokasi', AppTheme.warning);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showSnackBar('Izin lokasi ditolak', AppTheme.warning);
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar(
              'Izin lokasi ditolak permanen. Aktifkan di pengaturan.',
              AppTheme.danger);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal mendapatkan lokasi: $e', AppTheme.danger);
      }
    }

    setState(() => _isGettingLocation = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetForm() {
    // Remove focus from any text field first
    FocusScope.of(context).unfocus();
    // Clear the text controller explicitly
    _deskripsiController.clear();
    // Rebuild the entire form with a new key to guarantee all fields are fresh
    setState(() {
      _image = null;
      _latitude = null;
      _longitude = null;
      _formKey = GlobalKey<FormState>();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_image == null) {
      _showSnackBar('Ambil foto terlebih dahulu', AppTheme.danger);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar('Ambil lokasi terlebih dahulu', AppTheme.danger);
      return;
    }

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final success = await reportProvider.createReport(
      image: _image!,
      deskripsi: _deskripsiController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
    );

    if (success && mounted) {
      // Show success dialog then auto-reset
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Laporan Terkirim!',
                style: AppTheme.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan Anda berhasil dikirim dan akan segera diproses.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );

      // Auto-reset form after dialog closed
      _resetForm();
    } else if (mounted) {
      _showSnackBar(
        reportProvider.errorMessage ?? 'Gagal mengirim laporan',
        AppTheme.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Buat Laporan',
                        style: AppTheme.headingMedium
                            .copyWith(color: Colors.white, fontSize: 21),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Laporkan masalah sampah di sekitarmu',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== PHOTO =====
                    _SectionLabel(
                      icon: Icons.camera_alt_rounded,
                      label: 'Foto Bukti',
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.textLight.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Pilih Sumber Foto',
                                      style: AppTheme.headingSmall),
                                  const SizedBox(height: 16),
                                  _BottomSheetOption(
                                    icon: Icons.camera_alt_rounded,
                                    title: 'Ambil Foto',
                                    subtitle: 'Gunakan kamera',
                                    color: AppTheme.primary,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _BottomSheetOption(
                                    icon: Icons.photo_library_rounded,
                                    title: 'Pilih dari Galeri',
                                    subtitle: 'Pilih foto yang ada',
                                    color: AppTheme.info,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickFromGallery();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _image != null
                                ? AppTheme.primary.withOpacity(0.3)
                                : const Color(0xFFE8ECF0),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_image!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _image = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 32,
                                      color: AppTheme.primary.withOpacity(0.4),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap untuk ambil foto',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.primary.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== DESKRIPSI =====
                    _SectionLabel(
                      icon: Icons.edit_note_rounded,
                      label: 'Deskripsi',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      style: AppTheme.bodyLarge,
                      decoration: AppTheme.inputDecoration(
                        label: '',
                        icon: Icons.description_outlined,
                        hint: 'Jelaskan masalah sampah yang Anda temui...',
                      ).copyWith(
                        labelText: null,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Deskripsi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ===== LOKASI =====
                    _SectionLabel(
                      icon: Icons.location_on_rounded,
                      label: 'Lokasi GPS',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _latitude != null
                            ? AppTheme.success.withOpacity(0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _latitude != null
                              ? AppTheme.success.withOpacity(0.25)
                              : const Color(0xFFE8ECF0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_latitude != null && _longitude != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.success,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lokasi berhasil didapat',
                                        style: AppTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.success,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isGettingLocation ? null : _getLocation,
                              icon: _isGettingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded,
                                      size: 18),
                              label: Text(
                                _isGettingLocation
                                    ? 'Mendapatkan lokasi...'
                                    : _latitude != null
                                        ? 'Perbarui Lokasi'
                                        : 'Ambil Lokasi Saat Ini',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                    color: AppTheme.primary, width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ===== SUBMIT =====
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            reportProvider.isLoading ? null : _submit,
                        icon: reportProvider.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          reportProvider.isLoading
                              ? 'Mengirim...'
                              : 'Kirim Laporan',
                          style: AppTheme.buttonText,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primary.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.headingSmall.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
