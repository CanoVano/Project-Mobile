class AppNotification {
  final int id;
  final int userId;
  final int reportId;
  final String message;
  final bool isRead;
  final String? createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      reportId: json['report_id'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
    );
  }
}
