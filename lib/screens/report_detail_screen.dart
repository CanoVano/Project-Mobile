import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/report_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ReportProvider>(context, listen: false)
          .fetchReportDetail(widget.reportId);
    });
  }

  String _buildImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiService.storageUrl}/$path';
  }

  Future<void> _openLocation(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final report = reportProvider.currentReport;

    return Scaffold(
      body: reportProvider.isLoading || report == null
          ? Container(
              decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : CustomScrollView(
              slivers: [
                // ===== HEADER with Hero Image =====
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Before Image
                      Container(
                        height: 300,
                        width: double.infinity,
                        color: AppTheme.background,
                        child: report.fotoBefore.isNotEmpty
                            ? Image.network(
                                _buildImageUrl(report.fotoBefore),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 64, color: AppTheme.textLight),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.image_outlined,
                                    size: 64, color: AppTheme.textLight),
                              ),
                      ),
                      // Gradient overlay
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      // Back Button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // Status Badge on Image
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.getStatusColor(report.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppTheme.getStatusIcon(report.status),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                report.statusLabel,
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // "Before" label
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Foto Sebelum',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== CONTENT =====
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== STATUS TIMELINE =====
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📊 Status Laporan',
                                      style: AppTheme.headingSmall),
                                  const SizedBox(height: 16),
                                  _StatusStep(
                                    title: 'Menunggu',
                                    isActive: true,
                                    isCompleted: report.status == 'diproses' ||
                                        report.status == 'selesai',
                                  ),
                                  _StatusStep(
                                    title: 'Diproses',
                                    isActive: report.status == 'diproses' ||
                                        report.status == 'selesai',
                                    isCompleted: report.status == 'selesai',
                                  ),
                                  _StatusStep(
                                    title: 'Selesai',
                                    isActive: report.status == 'selesai',
                                    isCompleted: report.status == 'selesai',
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ===== DESKRIPSI =====
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📝 Deskripsi',
                                      style: AppTheme.headingSmall),
                                  const SizedBox(height: 12),
                                  Text(
                                    report.deskripsi,
                                    style: AppTheme.bodyLarge.copyWith(
                                        height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ===== LOKASI =====
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📍 Lokasi',
                                      style: AppTheme.headingSmall),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openLocation(
                                          report.latitude, report.longitude),
                                      icon: const Icon(
                                          Icons.map_outlined, size: 20),
                                      label:
                                          const Text('Lihat di Google Maps'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.info,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ===== FOTO AFTER (jika selesai) =====
                            if (report.status == 'selesai' &&
                                report.fotoAfter != null &&
                                report.fotoAfter!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        AppTheme.success.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success
                                          .withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons
                                                .check_circle_rounded,
                                            color: AppTheme.success,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '📸 Foto Sesudah',
                                          style: AppTheme.headingSmall
                                              .copyWith(
                                                  color:
                                                      AppTheme.success),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                        _buildImageUrl(
                                            report.fotoAfter!),
                                        width: double.infinity,
                                        height: 240,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                Container(
                                          height: 240,
                                          color: AppTheme.background,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .broken_image_outlined,
                                              size: 48,
                                              color:
                                                  AppTheme.textLight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ===== Date info =====
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18,
                                      color: AppTheme.textLight),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dibuat: ${report.createdAt?.substring(0, 10) ?? '-'}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.isActive,
    required this.isCompleted,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? (isCompleted ? AppTheme.success : AppTheme.statusDiproses)
                    : AppTheme.textLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : isActive
                      ? const Icon(Icons.radio_button_checked,
                          color: Colors.white, size: 16)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted
                    ? AppTheme.success
                    : AppTheme.textLight.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppTheme.textPrimary : AppTheme.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
