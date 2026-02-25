import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserProfile? _profile;
  UserStats? _stats;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserProfile? get profile => _profile;
  UserStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  ApiService get api => _api;

  // Raccourcis pour compatibilité
  String? get username => _profile?.username;
  String? get email => _profile?.email;
  int? get userId => _profile?.id;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _isAuthenticated = true;
      // Charger le profil depuis le cache
      final profileJson = prefs.getString('user_profile');
      if (profileJson != null) {
        try {
          _profile = UserProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);
        } catch (_) {}
      }
      notifyListeners();
      // Rafraîchir le profil en arrière-plan
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    final profile = await _api.getProfile();
    if (profile != null) {
      _profile = profile;
      notifyListeners();
    }
  }

  Future<(bool, String?)> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final (result, error) = await _api.login(email, password);
    _isLoading = false;

    if (result != null && result['user'] != null) {
      _isAuthenticated = true;
      _profile = UserProfile.fromJson(result['user'] as Map<String, dynamic>);
      _errorMessage = null;
      notifyListeners();
      return (true, null);
    }

    _errorMessage = error;
    notifyListeners();
    return (false, error);
  }

  Future<(bool, String?)> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final (result, error) = await _api.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    _isLoading = false;

    if (result != null && result['user'] != null) {
      _isAuthenticated = true;
      _profile = UserProfile.fromJson(result['user'] as Map<String, dynamic>);
      _errorMessage = null;
      notifyListeners();
      return (true, null);
    }

    _errorMessage = error;
    notifyListeners();
    return (false, error);
  }

  Future<void> logout() async {
    await _api.logout();
    _isAuthenticated = false;
    _profile = null;
    _stats = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logoutAll() async {
    await _api.logoutAll();
    _isAuthenticated = false;
    _profile = null;
    _stats = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final profile = await _api.getProfile();
    if (profile != null) {
      _profile = profile;
      notifyListeners();
    }
  }

  Future<(bool, String?)> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    notifyListeners();

    final (profile, error) = await _api.updateProfile(
      username: username,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dateOfBirth: dateOfBirth,
    );
    _isLoading = false;

    if (profile != null) {
      _profile = profile;
      notifyListeners();
      return (true, null);
    }
    notifyListeners();
    return (false, error);
  }

  Future<(bool, String?)> updatePreferences({
    String? dietType,
    String? allergies,
    String? dietaryGoals,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
  }) async {
    final (profile, error) = await _api.updatePreferences(
      dietType: dietType,
      allergies: allergies,
      dietaryGoals: dietaryGoals,
      notificationsEnabled: notificationsEnabled,
      darkModeEnabled: darkModeEnabled,
      language: language,
    );
    if (profile != null) {
      _profile = profile;
      notifyListeners();
      return (true, null);
    }
    return (false, error);
  }

  Future<void> loadStats() async {
    _stats = await _api.getStats();
    notifyListeners();
  }

  Future<(bool, String?)> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    final (success, error) = await _api.changePassword(currentPassword, newPassword);
    _isLoading = false;
    notifyListeners();

    if (success) {
      // Après changement de mot de passe, forcer une reconnexion
      await _api.clearTokens();
      _isAuthenticated = false;
      _profile = null;
      notifyListeners();
    }
    return (success, error);
  }

  Future<(bool, String?)> forgotPassword(String email) async {
    return await _api.forgotPassword(email);
  }

  Future<(bool, String?)> deleteAccount(String password) async {
    _isLoading = true;
    notifyListeners();

    final (success, error) = await _api.deleteAccount(password);
    _isLoading = false;

    if (success) {
      _isAuthenticated = false;
      _profile = null;
      _stats = null;
    }
    notifyListeners();
    return (success, error);
  }
}
