import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ReportProvider>(context, listen: false).fetchReports();
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await reportProvider.fetchReports();
          await authProvider.refreshProfile();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ===== HEADER =====
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
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo! 👋',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.user?.name ?? 'User',
                                style: AppTheme.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildAvatar(authProvider),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Total card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Laporan',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${reportProvider.totalReports}',
                                style: AppTheme.headingLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== STATUS CARDS =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan Status', style: AppTheme.headingSmall),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusCard(
                            title: 'Menunggu',
                            count: reportProvider.menungguCount,
                            icon: Icons.schedule_rounded,
                            color: AppTheme.statusMenunggu,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatusCard(
                            title: 'Diproses',
                            count: reportProvider.diprosesCount,
                            icon: Icons.engineering_rounded,
                            color: AppTheme.statusDiproses,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatusCard(
                            title: 'Selesai',
                            count: reportProvider.selesaiCount,
                            icon: Icons.check_circle_rounded,
                            color: AppTheme.statusSelesai,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== RECENT REPORTS =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text('Laporan Terbaru', style: AppTheme.headingSmall),
              ),
            ),

            if (reportProvider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else if (reportProvider.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reportProvider.errorMessage!,
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (reportProvider.reports.isEmpty)
              SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reportProvider.reports[index];
                      return _RecentReportCard(report: report);
                    },
                    childCount: reportProvider.reports.length > 5
                        ? 5
                        : reportProvider.reports.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthProvider authProvider) {
    final photoPath = authProvider.localPhotoPath;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasPhoto
            ? Image.file(File(photoPath), fit: BoxFit.cover)
            : Center(
                child: Text(
                  (authProvider.user?.name ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: AppTheme.headingSmall.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: AppTheme.headingMedium.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 48,
                color: AppTheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada laporan',
              style:
                  AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Buat laporan pertamamu!',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  final dynamic report;

  const _RecentReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Thumbnail — FIXED: Use ApiService.buildImageUrl
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 58,
              color: AppTheme.background,
              child: report.fotoBefore.isNotEmpty
                  ? Image.network(
                      ApiService.buildImageUrl(report.fotoBefore),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: AppTheme.textLight,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppTheme.textLight,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.deskripsi,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  report.createdAt?.substring(0, 10) ?? '-',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.statusLabel,
              style: AppTheme.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
