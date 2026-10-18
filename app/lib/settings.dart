// =============================================
// settings.dart - Guarda o endereço do servidor no celular
// =============================================

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static const _serverKey = 'server_url';
  static const _overviewKey = 'cached_overview';
  static const _overviewAtKey = 'cached_overview_at';
  static const _historyPrefix = 'cached_history_';
  static const _historyAtPrefix = 'cached_history_at_';

  static Future<String?> loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverKey);
  }

  static Future<void> saveServer(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverKey, url);
  }

  static Future<void> saveOverview(String json, DateTime savedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overviewKey, json);
    await prefs.setString(_overviewAtKey, savedAt.toIso8601String());
  }

  static Future<CachedPayload?> loadOverview() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadPayload(prefs, _overviewKey, _overviewAtKey);
  }

  static Future<void> saveHistory(String sensorId, String json, DateTime savedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _safeKey(sensorId);
    await prefs.setString('$_historyPrefix$key', json);
    await prefs.setString('$_historyAtPrefix$key', savedAt.toIso8601String());
  }

  static Future<CachedPayload?> loadHistory(String sensorId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _safeKey(sensorId);
    return _loadPayload(prefs, '$_historyPrefix$key', '$_historyAtPrefix$key');
  }

  static String _safeKey(String value) => Uri.encodeComponent(value);

  static CachedPayload? _loadPayload(
    SharedPreferences prefs,
    String payloadKey,
    String timestampKey,
  ) {
    final payload = prefs.getString(payloadKey);
    final timestamp = prefs.getString(timestampKey);
    if (payload == null || timestamp == null) return null;
    final savedAt = DateTime.tryParse(timestamp);
    if (savedAt == null) return null;
    return CachedPayload(json: payload, savedAt: savedAt);
  }
}

class CachedPayload {
  const CachedPayload({required this.json, required this.savedAt});

  final String json;
  final DateTime savedAt;
}
