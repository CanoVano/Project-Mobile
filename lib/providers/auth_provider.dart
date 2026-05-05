import 'dart:async';
import 'dart:convert';
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
  String? _localPhotoPath;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get localPhotoPath => _localPhotoPath;

  Future<void> checkLoginStatus() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      // Step 1: ALWAYS restore from local storage first so user is never kicked out
      final localUser = await _loadUserData();
      if (localUser != null) {
        _user = localUser;
        _isLoggedIn = true;
        await _loadLocalProfile();
        notifyListeners();
      }

      // Step 2: Try to refresh profile from API (updates local data if successful)
      try {
        final data = await ApiService.getProfile();
        if (data.containsKey('id')) {
          _user = User.fromJson(data);
          _isLoggedIn = true;
          await _saveUserData(_user!);
        } else if (data.containsKey('data')) {
          _user = User.fromJson(data['data']);
          _isLoggedIn = true;
          await _saveUserData(_user!);
        } else if (data.containsKey('user')) {
          _user = User.fromJson(data['user']);
          _isLoggedIn = true;
          await _saveUserData(_user!);
        } else if (data.containsKey('message') &&
            data['message'].toString().toLowerCase().contains('unauth')) {
          // Token is truly expired/invalid — only then clear session
          _user = null;
          _isLoggedIn = false;
          await ApiService.removeToken();
          await _clearUserData();
        }
        // If API returned something unrecognized, keep the local session alive
        await _loadLocalProfile();
      } catch (_) {
        // Network error — keep local session alive, don't clear anything
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
          await _saveUserData(_user!);
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
          await _saveUserData(_user!);
        } else {
          // API didn't return user data with the token — fetch it now
          try {
            final profileData = await ApiService.getProfile();
            if (profileData.containsKey('id')) {
              _user = User.fromJson(profileData);
            } else if (profileData.containsKey('data')) {
              _user = User.fromJson(profileData['data']);
            } else if (profileData.containsKey('user')) {
              _user = User.fromJson(profileData['user']);
            }
            if (_user != null) await _saveUserData(_user!);
          } catch (_) {}
        }
        _isLoggedIn = true;
        _isLoading = false;
        // Load local profile overrides
        await _loadLocalProfile();
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
    _localPhotoPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _clearUserData();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await ApiService.getProfile();
      if (data.containsKey('id')) {
        _user = User.fromJson(data);
        await _saveUserData(_user!);
      } else if (data.containsKey('data')) {
        _user = User.fromJson(data['data']);
        await _saveUserData(_user!);
      } else if (data.containsKey('user')) {
        _user = User.fromJson(data['user']);
        await _saveUserData(_user!);
      }
      // Re-apply local overrides
      await _loadLocalProfile();
      notifyListeners();
    } catch (_) {}
  }

  // ==================== PROFILE UPDATE ====================

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _localPhotoPath = prefs.getString('local_profile_photo');
  }

  /// Persist user data to SharedPreferences for session restoration
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'foto_profil': user.fotoProfil,
    }));
  }

  /// Load persisted user data from SharedPreferences
  Future<User?> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        final json = jsonDecode(userData) as Map<String, dynamic>;
        return User.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clear persisted user data
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  /// Update profile: name is sent to the API, photo is stored locally.
  /// Returns error message if failed, null if success.
  Future<String?> updateProfile({String? name, String? photoPath}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Update name via API
    if (name != null && name.isNotEmpty) {
      try {
        final data = await ApiService.updateProfile(name: name);
        if (data.containsKey('user')) {
          _user = User.fromJson(data['user']);
        } else if (data.containsKey('message') && !data.containsKey('errors')) {
          // Success but no user object returned, update locally
          if (_user != null) {
            _user = _user!.copyWith(name: name);
          }
        } else {
          // Error from server
          String errorMsg = data['message'] ?? 'Gagal memperbarui profil';
          if (data.containsKey('errors')) {
            final errors = data['errors'] as Map<String, dynamic>;
            errorMsg = errors.values.first is List
                ? (errors.values.first as List).first.toString()
                : errors.values.first.toString();
          }
          _errorMessage = errorMsg;
          _isLoading = false;
          notifyListeners();
          return errorMsg;
        }
      } catch (e) {
        _errorMessage = 'Gagal terhubung ke server: $e';
        _isLoading = false;
        notifyListeners();
        return _errorMessage;
      }
    }

    // Update photo locally (backend doesn't support photo upload yet)
    if (photoPath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_photo', photoPath);
      _localPhotoPath = photoPath;
    }

    _isLoading = false;
    notifyListeners();
    return null; // success
  }
}

