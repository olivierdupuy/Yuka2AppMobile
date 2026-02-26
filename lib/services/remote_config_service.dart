import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Holds the remote configuration fetched from the backend.
class RemoteConfig {
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? minAppVersion;
  final String? latestAppVersion;
  final String? forceUpdateMessage;
  final bool scanEnabled;
  final bool searchEnabled;
  final bool favoritesEnabled;
  final bool registrationEnabled;
  final bool historyEnabled;
  final bool openFoodFactsEnabled;
  final bool biometricAuthEnabled;
  final bool accountDeletionEnabled;
  final bool passwordResetEnabled;

  const RemoteConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.minAppVersion,
    this.latestAppVersion,
    this.forceUpdateMessage,
    this.scanEnabled = true,
    this.searchEnabled = true,
    this.favoritesEnabled = true,
    this.registrationEnabled = true,
    this.historyEnabled = true,
    this.openFoodFactsEnabled = true,
    this.biometricAuthEnabled = true,
    this.accountDeletionEnabled = true,
    this.passwordResetEnabled = true,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      minAppVersion: json['minAppVersion'] as String?,
      latestAppVersion: json['latestAppVersion'] as String?,
      forceUpdateMessage: json['forceUpdateMessage'] as String?,
      scanEnabled: json['scanEnabled'] as bool? ?? true,
      searchEnabled: json['searchEnabled'] as bool? ?? true,
      favoritesEnabled: json['favoritesEnabled'] as bool? ?? true,
      registrationEnabled: json['registrationEnabled'] as bool? ?? true,
      historyEnabled: json['historyEnabled'] as bool? ?? true,
      openFoodFactsEnabled: json['openFoodFactsEnabled'] as bool? ?? true,
      biometricAuthEnabled: json['biometricAuthEnabled'] as bool? ?? true,
      accountDeletionEnabled: json['accountDeletionEnabled'] as bool? ?? true,
      passwordResetEnabled: json['passwordResetEnabled'] as bool? ?? true,
    );
  }

  /// Compare semver strings. Returns true if [current] < [minimum].
  static bool isVersionBelow(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minimum.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  bool get requiresUpdate =>
      minAppVersion != null &&
      isVersionBelow(RemoteConfigService.appVersion, minAppVersion!);
}

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String _baseUrl = 'http://192.168.1.30:5000/api';
  static const String appVersion = '1.0.0';

  RemoteConfig _config = const RemoteConfig();
  RemoteConfig get config => _config;

  /// Listeners notified whenever the config changes.
  final List<void Function(RemoteConfig)> _listeners = [];

  void addListener(void Function(RemoteConfig) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(RemoteConfig) listener) {
    _listeners.remove(listener);
  }

  /// Fetch the remote configuration from the backend.
  Future<RemoteConfig> fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newConfig = RemoteConfig.fromJson(data);
        final changed = newConfig.maintenanceMode != _config.maintenanceMode ||
            newConfig.requiresUpdate != _config.requiresUpdate;
        _config = newConfig;
        if (changed) {
          for (final listener in _listeners) {
            listener(_config);
          }
        }
      }
    } catch (e) {
      debugPrint('RemoteConfig fetch failed: $e');
    }
    return _config;
  }
}
