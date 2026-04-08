import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        final data = await ApiService.getProfile();
        if (data.containsKey('id')) {
          _user = User.fromJson(data);
          _isLoggedIn = true;
        } else if (data.containsKey('data')) {
          _user = User.fromJson(data['data']);
          _isLoggedIn = true;
        }
      } catch (_) {
        _isLoggedIn = false;
        await ApiService.removeToken();
      }
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (data.containsKey('token')) {
        await ApiService.saveToken(data['token']);
        if (data.containsKey('user')) {
          _user = User.fromJson(data['user']);
        }
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Registrasi gagal';
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          _errorMessage = errors.values.first is List
              ? (errors.values.first as List).first.toString()
              : errors.values.first.toString();
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException {
      _errorMessage = 'Server tidak merespon (timeout). Pastikan server API berjalan.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet dan IP server.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.login(email: email, password: password);

      if (data.containsKey('token')) {
        await ApiService.saveToken(data['token']);
        if (data.containsKey('user')) {
          _user = User.fromJson(data['user']);
        }
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException {
      _errorMessage = 'Server tidak merespon (timeout). Pastikan server API berjalan.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet dan IP server.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    _user = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await ApiService.getProfile();
      if (data.containsKey('id')) {
        _user = User.fromJson(data);
      } else if (data.containsKey('data')) {
        _user = User.fromJson(data['data']);
      }
      notifyListeners();
    } catch (_) {}
  }
}
