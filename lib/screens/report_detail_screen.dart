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
      backgroundColor: AppTheme.background,
      body: reportProvider.isLoading || report == null
          ? Container(
              decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ===== HEADER with Hero Image =====
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Before Image — FIXED: Use ApiService.buildImageUrl
                      Container(
                        height: 300,
                        width: double.infinity,
                        color: AppTheme.background,
                        child: report.fotoBefore.isNotEmpty
                            ? Image.network(
                                ApiService.buildImageUrl(report.fotoBefore),
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary.withOpacity(0.3),
                                    ),
                                  );
                                },
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
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
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
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
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
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.getStatusColor(report.status)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppTheme.getStatusIcon(report.status),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                report.statusLabel,
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Foto Sebelum',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
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
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: const BorderRadius.only(
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
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timeline_rounded,
                                          size: 18, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Status Laporan',
                                          style: AppTheme.headingSmall
                                              .copyWith(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _StatusStep(
                                    title: 'Menunggu',
                                    subtitle: 'Laporan telah diterima',
                                    isActive: true,
                                    isCompleted:
                                        report.status == 'diproses' ||
                                            report.status == 'selesai',
                                  ),
                                  _StatusStep(
                                    title: 'Diproses',
                                    subtitle: 'Sedang ditangani petugas',
                                    isActive:
                                        report.status == 'diproses' ||
                                            report.status == 'selesai',
                                    isCompleted:
                                        report.status == 'selesai',
                                  ),
                                  _StatusStep(
                                    title: 'Selesai',
                                    subtitle: 'Masalah telah diselesaikan',
                                    isActive: report.status == 'selesai',
                                    isCompleted:
                                        report.status == 'selesai',
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ===== DESKRIPSI =====
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded,
                                          size: 18,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Deskripsi',
                                          style: AppTheme.headingSmall
                                              .copyWith(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    report.deskripsi,
                                    style: AppTheme.bodyLarge
                                        .copyWith(height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ===== LOKASI =====
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 18,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Lokasi',
                                          style: AppTheme.headingSmall
                                              .copyWith(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openLocation(
                                          report.latitude,
                                          report.longitude),
                                      icon: const Icon(Icons.map_rounded,
                                          size: 18),
                                      label: const Text(
                                          'Lihat di Google Maps'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.info,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        textStyle: AppTheme.buttonText
                                            .copyWith(fontSize: 14),
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
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        AppTheme.success.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success
                                          .withOpacity(0.06),
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
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.success,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Foto Sesudah',
                                          style: AppTheme.headingSmall
                                              .copyWith(
                                            color: AppTheme.success,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                        ApiService.buildImageUrl(
                                            report.fotoAfter!),
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (_, child, progress) {
                                          if (progress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: 220,
                                            color: AppTheme.background,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.primary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                          height: 220,
                                          color: AppTheme.background,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .broken_image_outlined,
                                              size: 48,
                                              color: AppTheme.textLight,
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
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration,
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 16,
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
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.subtitle,
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
                    ? (isCompleted
                        ? AppTheme.success
                        : AppTheme.statusDiproses)
                    : AppTheme.textLight.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: (isCompleted
                                  ? AppTheme.success
                                  : AppTheme.statusDiproses)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : isActive
                      ? const Icon(Icons.radio_button_checked,
                          color: Colors.white, size: 14)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.success.withOpacity(0.5)
                      : AppTheme.textLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: isActive
                        ? AppTheme.textSecondary
                        : AppTheme.textLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
