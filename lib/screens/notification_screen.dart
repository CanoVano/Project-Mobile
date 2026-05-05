import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';
import 'report_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return dateStr.substring(0, 10);
    } catch (_) {
      return dateStr.length > 16 ? dateStr.substring(0, 16) : dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppTheme.primary;
    switch (status.toLowerCase()) {
      case 'menunggu':
        return AppTheme.statusMenunggu;
      case 'diproses':
      case 'di proses':
        return AppTheme.statusDiproses;
      case 'selesai':
        return AppTheme.statusSelesai;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.notifications_rounded;
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Icons.schedule_rounded;
      case 'diproses':
      case 'di proses':
        return Icons.engineering_rounded;
      case 'selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: () => notifProvider.fetchNotifications(),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifikasi',
                      style: AppTheme.headingMedium
                          .copyWith(color: Colors.white, fontSize: 21),
                    ),
                    const Spacer(),
                    if (notifProvider.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '${notifProvider.unreadCount} baru',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content
            if (notifProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 3,
                  ),
                ),
              )
            else if (notifProvider.notifications.isEmpty)
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
                          Icons.notifications_off_rounded,
                          size: 48,
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: AppTheme.bodyLarge
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notifikasi akan muncul di sini',
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
                      final notif = notifProvider.notifications[index];
                      final statusColor = _getStatusColor(notif.status);
                      final statusIcon = _getStatusIcon(notif.status);

                      return GestureDetector(
                        onTap: () {
                          if (!notif.isRead) {
                            notifProvider.markAsRead(notif.id);
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailScreen(
                                  reportId: notif.reportId),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? Colors.white
                                : statusColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: notif.isRead
                                ? Border.all(color: const Color(0xFFF0F2F5))
                                : Border.all(
                                    color: statusColor.withOpacity(0.15),
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status icon with color
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: notif.isRead
                                      ? AppTheme.textLight.withOpacity(0.08)
                                      : statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: notif.isRead
                                      ? AppTheme.textLight
                                      : statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.message,
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontWeight: notif.isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: AppTheme.textLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimeAgo(notif.createdAt),
                                          style: AppTheme.bodySmall,
                                        ),
                                        if (notif.status != null) ...[
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              notif.status!
                                                  .replaceAll(
                                                      'di proses', 'Diproses')
                                                  .replaceFirst(
                                                    notif.status![0],
                                                    notif.status![0]
                                                        .toUpperCase(),
                                                  ),
                                              style:
                                                  AppTheme.bodySmall.copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: notifProvider.notifications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
