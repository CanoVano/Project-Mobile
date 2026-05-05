class Report {
  final int id;
  final int userId;
  final String deskripsi;
  final String fotoBefore;
  final String? fotoAfter;
  final double latitude;
  final double longitude;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Report({
    required this.id,
    required this.userId,
    required this.deskripsi,
    required this.fotoBefore,
    this.fotoAfter,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Normalize status from API to internal format.
  /// API sends: "menunggu", "di proses", "selesai"
  /// Internal:  "menunggu", "diproses", "selesai"
  static String _normalizeStatus(String? raw) {
    if (raw == null || raw.isEmpty) return 'menunggu';
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'menunggu':
      case 'pending':
        return 'menunggu';
      case 'di proses':
      case 'diproses':
      case 'processing':
      case 'in_progress':
        return 'diproses';
      case 'selesai':
      case 'completed':
      case 'done':
        return 'selesai';
      default:
        return s;
    }
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    // Handle foto_after: API may send the string "null" instead of actual null
    String? fotoAfter = json['foto_after']?.toString();
    if (fotoAfter == 'null' || fotoAfter == '' || fotoAfter == null) {
      fotoAfter = null;
    }

    return Report(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      deskripsi: json['deskripsi']?.toString() ?? '',
      fotoBefore: json['foto_before']?.toString() ?? '',
      fotoAfter: fotoAfter,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      status: _normalizeStatus(json['status']?.toString()),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }
}
