import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'report_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ReportProvider>(context, listen: false).fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final reportProvider = Provider.of<ReportProvider>(context);

    final filteredReports = _filterStatus == 'semua'
        ? reportProvider.reports
        : reportProvider.reports
            .where((r) => r.status == _filterStatus)
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: () => reportProvider.fetchReports(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Riwayat Laporan',
                          style: AppTheme.headingMedium
                              .copyWith(color: Colors.white, fontSize: 21),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            count: reportProvider.totalReports,
                            isSelected: _filterStatus == 'semua',
                            onTap: () =>
                                setState(() => _filterStatus = 'semua'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Menunggu',
                            count: reportProvider.menungguCount,
                            isSelected: _filterStatus == 'menunggu',
                            onTap: () =>
                                setState(() => _filterStatus = 'menunggu'),
                            color: AppTheme.statusMenunggu,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Diproses',
                            count: reportProvider.diprosesCount,
                            isSelected: _filterStatus == 'diproses',
                            onTap: () =>
                                setState(() => _filterStatus = 'diproses'),
                            color: AppTheme.statusDiproses,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Selesai',
                            count: reportProvider.selesaiCount,
                            isSelected: _filterStatus == 'selesai',
                            onTap: () =>
                                setState(() => _filterStatus = 'selesai'),
                            color: AppTheme.statusSelesai,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            if (reportProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 3,
                  ),
                ),
              )
            else if (filteredReports.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        'Tidak ada laporan',
                        style: AppTheme.bodyLarge
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filterStatus != 'semua'
                            ? 'Tidak ada laporan dengan status ini'
                            : 'Buat laporan pertamamu',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = filteredReports[index];
                      final statusColor =
                          AppTheme.getStatusColor(report.status);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailScreen(reportId: report.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.cardDecoration,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Thumbnail — FIXED: Use ApiService.buildImageUrl
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    color: AppTheme.background,
                                    child: report.fotoBefore.isNotEmpty
                                        ? Image.network(
                                            ApiService.buildImageUrl(
                                                report.fotoBefore),
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (_, child, progress) {
                                              if (progress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.primary
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.image_outlined,
                                              color: AppTheme.textLight,
                                              size: 26,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.image_outlined,
                                            color: AppTheme.textLight,
                                            size: 26,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.deskripsi,
                                        style: AppTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 12,
                                            color: AppTheme.textLight,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            report.createdAt
                                                    ?.substring(0, 10) ??
                                                '-',
                                            style: AppTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Status Badge
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        AppTheme.getStatusIcon(
                                            report.status),
                                        color: statusColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.statusLabel,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredReports.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color:
                    isSelected ? (color ?? AppTheme.primary) : Colors.white,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (color ?? AppTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppTheme.bodySmall.copyWith(
                    color: color ?? AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
