import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> _reports = [];
  Report? _currentReport;
  bool _isLoading = false;
  String? _errorMessage;

  List<Report> get reports => _reports;
  Report? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalReports => _reports.length;
  int get menungguCount => _reports.where((r) => r.status == 'menunggu').length;
  int get diprosesCount => _reports.where((r) => r.status == 'diproses').length;
  int get selesaiCount => _reports.where((r) => r.status == 'selesai').length;

  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getReports();
      _reports = data.map((json) => Report.fromJson(json)).toList();
      // Sort by newest
      _reports.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    } catch (e) {
      _errorMessage = 'Gagal memuat laporan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReportDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getReportDetail(id);
      if (data.containsKey('data')) {
        _currentReport = Report.fromJson(data['data']);
      } else if (data.containsKey('report')) {
        _currentReport = Report.fromJson(data['report']);
      } else {
        _currentReport = Report.fromJson(data);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat detail laporan';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReport({
    required File image,
    required String deskripsi,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.createReport(
        image: image,
        deskripsi: deskripsi,
        latitude: latitude,
        longitude: longitude,
      );

      if (data.containsKey('data') || 
          data.containsKey('id') || 
          data.containsKey('report') ||
          (data.containsKey('message') && data['message'].toString().toLowerCase().contains('berhasil'))) {
        await fetchReports();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal membuat laporan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
