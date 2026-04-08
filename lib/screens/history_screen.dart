import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
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
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Riwayat Laporan',
                        style: AppTheme.headingMedium
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Semua',
                          isSelected: _filterStatus == 'semua',
                          onTap: () =>
                              setState(() => _filterStatus = 'semua'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Menunggu',
                          isSelected: _filterStatus == 'menunggu',
                          onTap: () =>
                              setState(() => _filterStatus = 'menunggu'),
                          color: AppTheme.statusMenunggu,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Diproses',
                          isSelected: _filterStatus == 'diproses',
                          onTap: () =>
                              setState(() => _filterStatus = 'diproses'),
                          color: AppTheme.statusDiproses,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Selesai',
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
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (filteredReports.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: AppTheme.textLight.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada laporan',
                      style: AppTheme.bodyLarge
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final report = filteredReports[index];
                    final statusColor = AppTheme.getStatusColor(report.status);

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
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: AppTheme.cardDecoration,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: AppTheme.background,
                                  child: report.fotoBefore.isNotEmpty
                                      ? Image.network(
                                          '${report.fotoBefore.startsWith("http") ? "" : "http://10.0.2.2:8000/storage/"}${report.fotoBefore}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.image_outlined,
                                            color: AppTheme.textLight,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.image_outlined,
                                          color: AppTheme.textLight,
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
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
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
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      AppTheme.getStatusIcon(report.status),
                                      color: statusColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.statusLabel,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? (color ?? AppTheme.primary) : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
