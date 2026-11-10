// =============================================
// settings.dart - Guarda o endereço do servidor no celular
// =============================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static const _serverKey = 'server_url';
  static const _overviewKey = 'cached_overview';
  static const _overviewAtKey = 'cached_overview_at';
  static const _historyPrefix = 'cached_history_';
  static const _historyAtPrefix = 'cached_history_at_';
  static const _residentsKey = 'admin_residents';

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

  static Future<List<Resident>> loadResidents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_residentsKey);
    if (raw == null) return <Resident>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Resident>[];
      return decoded
          .whereType<Map>()
          .map((item) => Resident.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on FormatException {
      return <Resident>[];
    }
  }

  static Future<void> saveResidents(List<Resident> residents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _residentsKey,
      jsonEncode(residents.map((resident) => resident.toJson()).toList()),
    );
  }
}

class CachedPayload {
  const CachedPayload({required this.json, required this.savedAt});

  final String json;
  final DateTime savedAt;
}

class Resident {
  const Resident({
    required this.id,
    required this.name,
    required this.contact,
    required this.channel,
    required this.house,
    required this.enabled,
  });

  final String id;
  final String name;
  final String contact;
  final String channel;
  final String house;
  final bool enabled;

  factory Resident.fromJson(Map<String, dynamic> json) => Resident(
        id: json['id'] is String ? json['id'] as String : '',
        name: json['name'] is String ? json['name'] as String : '',
        contact: json['contact'] is String ? json['contact'] as String : '',
        channel: json['channel'] is String ? json['channel'] as String : 'email',
        house: json['house'] is String ? json['house'] as String : '',
        enabled: json['enabled'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contact,
        'channel': channel,
        'house': house,
        'enabled': enabled,
      };
}
