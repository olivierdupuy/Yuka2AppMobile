import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrackingService {
  TrackingService._();
  static final TrackingService _instance = TrackingService._();
  static TrackingService get instance => _instance;

  static const String _baseUrl = 'http://192.168.1.30:5000/api';
  static const String _deviceIdKey = 'tracking_device_id';

  String? _deviceId;
  String? _sessionId;
  String? _authToken;

  String get _deviceModel {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown';
    }
  }

  String get _deviceOS {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Initialize the tracking service: load or generate deviceId, then start a session.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);
      if (_deviceId == null) {
        _deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, _deviceId!);
      }
      // Load auth token if available
      _authToken = prefs.getString('access_token');
      // Start initial session
      await startSession();
    } catch (_) {}
  }

  /// Update auth token (call after login/logout).
  void updateAuthToken(String? token) {
    _authToken = token;
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomPart = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
    return '$timestamp-$randomPart';
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Start a new tracking session, closing any previous one.
  Future<void> startSession() async {
    try {
      final previousSessionId = _sessionId;
      final response = await http.post(
        Uri.parse('$_baseUrl/tracking/session/start'),
        headers: _headers,
        body: jsonEncode({
          'deviceId': _deviceId,
          'deviceModel': _deviceModel,
          'deviceOS': _deviceOS,
          'appVersion': '1.0.0',
          if (previousSessionId != null) 'previousSessionId': previousSessionId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _sessionId = data['sessionId'] as String?;
      }
    } catch (_) {}
  }

  /// End the current tracking session.
  Future<void> endSession() async {
    if (_sessionId == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/tracking/session/end'),
        headers: _headers,
        body: jsonEncode({'sessionId': _sessionId}),
      );
      _sessionId = null;
    } catch (_) {}
  }

  /// Track a page view (fire-and-forget).
  void trackPageView(String pageName) {
    if (_sessionId == null) return;
    try {
      http.post(
        Uri.parse('$_baseUrl/tracking/pageview'),
        headers: _headers,
        body: jsonEncode({
          'sessionId': _sessionId,
          'pageName': pageName,
        }),
      );
    } catch (_) {}
  }

  /// Track an event (fire-and-forget).
  void trackEvent(String eventType, {Map<String, dynamic>? data}) {
    if (_sessionId == null) return;
    try {
      http.post(
        Uri.parse('$_baseUrl/tracking/event'),
        headers: _headers,
        body: jsonEncode({
          'sessionId': _sessionId,
          'eventType': eventType,
          if (data != null) 'eventData': data,
          'deviceId': _deviceId,
        }),
      );
    } catch (_) {}
  }
}
