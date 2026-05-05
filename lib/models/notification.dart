class AppNotification {
  final int id;
  final int userId;
  final int reportId;
  final String message;
  final bool isRead;
  final String? createdAt;
  final String? status;

  AppNotification({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.status,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Try to extract status from the notification or related report data
    String? status = json['status']?.toString();
    if (status == 'null' || status == '') status = null;

    // If status is not directly available, try from nested report
    if (status == null && json['report'] is Map) {
      status = json['report']['status']?.toString();
    }

    // If still null, try to infer from message content
    if (status == null) {
      final msg = (json['message'] ?? '').toString().toLowerCase();
      if (msg.contains('selesai') || msg.contains('completed')) {
        status = 'selesai';
      } else if (msg.contains('diproses') || msg.contains('di proses') || msg.contains('proses')) {
        status = 'diproses';
      } else if (msg.contains('menunggu') || msg.contains('pending') || msg.contains('baru')) {
        status = 'menunggu';
      }
    }

    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      reportId: json['report_id'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
      status: status,
    );
  }
}
