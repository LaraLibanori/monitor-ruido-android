// =============================================
// api.dart - Conversa com o servidor (FastAPI no Docker)
// =============================================
// Leitura das casas:
//   GET /api/app/overview
//   GET /api/app/houses/{sensor_id}/history
// Conta (token Bearer devolvido no login):
//   /api/auth/*  login, logout, convite
//   /api/me/*    preferências, aparelho, alertas
//   /api/admin/* moradores e casas (só administrador)
// =============================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro com mensagem já pronta para mostrar ao usuário.
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// O servidor recusou o token (sessão expirada) ou exige login.
class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Sua sessão expirou. Entre novamente.']);
}

int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double? _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value');
String? _toString(dynamic value) => value is String ? value : null;
List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];
Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map<String, dynamic>((key, value) => MapEntry('$key', value));
  }
  return const <String, dynamic>{};
}

// ---------------------------------------------
// Modelos
// ---------------------------------------------

class NextChange {
  NextChange({required this.at, required this.dayOffset, required this.silenceStarts});

  final String at; // "22:00"
  final int dayOffset; // 0 = hoje, 1 = amanhã
  final bool silenceStarts; // true = o silêncio vai começar

  factory NextChange.fromJson(Map<String, dynamic> json) => NextChange(
        at: _toString(json['at']) ?? '',
        dayOffset: _toInt(json['day_offset']),
        silenceStarts: json['silence_starts'] == true,
      );
}

class SilenceStatus {
  SilenceStatus({
    required this.active,
    required this.next,
    required this.weekdayRule,
    required this.weekendRule,
  });

  final bool active;
  final NextChange? next;
  final String weekdayRule; // "22:00–09:00"
  final String weekendRule; // "15:00–09:00"

  factory SilenceStatus.fromJson(Map<String, dynamic> json) {
    final rules = _map(json['rules']);
    final next = json['next_change'];
    return SilenceStatus(
      active: json['is_silence_period'] == true,
      next: next is Map ? NextChange.fromJson(_map(next)) : null,
      weekdayRule: _toString(rules['weekday']) ?? '',
      weekendRule: _toString(rules['weekend']) ?? '',
    );
  }
}

class House {
  House({
    required this.sensorId,
    required this.name,
    required this.location,
    required this.online,
    required this.secondsSinceLast,
    required this.level,
    required this.rms,
    required this.readingInSilence,
    required this.todayReadings,
    required this.todayLoudInSilence,
  });

  final String sensorId;
  final String name; // "Casa 1"
  final String location;
  final bool online;
  final int? secondsSinceLast; // null = nunca enviou dados
  final String? level; // baixo | medio | alto | muito_alto
  final double? rms;
  final bool readingInSilence;
  final int todayReadings;
  final int todayLoudInSilence;

  factory House.fromJson(Map<String, dynamic> json) {
    final last = json['last_reading'];
    final lastMap = last == null ? null : _map(last);
    final today = _map(json['today']);
    final seconds = json['seconds_since_last'];
    return House(
      sensorId: _toString(json['sensor_id']) ?? '',
      name: _toString(json['name']) ?? (_toString(json['sensor_id']) ?? ''),
      location: _toString(json['location']) ?? '',
      online: json['online'] == true,
      secondsSinceLast: seconds == null ? null : _toInt(seconds),
      level: _toString(lastMap?['noise_level']),
      rms: _toDouble(lastMap?['rms']),
      readingInSilence: lastMap?['is_silence_period'] == true,
      todayReadings: _toInt(today['readings']),
      todayLoudInSilence: _toInt(today['loud_in_silence']),
    );
  }
}

class Overview {
  Overview({required this.silence, required this.houses});

  final SilenceStatus silence;
  final List<House> houses;

  factory Overview.fromJson(Map<String, dynamic> json) => Overview(
        silence: SilenceStatus.fromJson(_map(json['silence'])),
        houses: _list(json['houses'])
            .whereType<Map>()
            .map((item) => House.fromJson(_map(item)))
            .toList(),
      );
}

class HourBucket {
  HourBucket({
    required this.hour,
    required this.isSilence,
    required this.readings,
    required this.avgRms,
    required this.worstLevel,
    required this.loud,
    required this.loudInSilence,
  });

  final int hour;
  final bool isSilence;
  final int readings;
  final double? avgRms;
  final String? worstLevel;
  final int loud;
  final int loudInSilence;

  factory HourBucket.fromJson(Map<String, dynamic> json) => HourBucket(
        hour: _toInt(json['hour']),
        isSilence: json['is_silence'] == true,
        readings: _toInt(json['readings']),
        avgRms: _toDouble(json['avg_rms']),
        worstLevel: _toString(json['worst_level']),
        loud: _toInt(json['loud']),
        loudInSilence: _toInt(json['loud_in_silence']),
      );
}

class History {
  History({
    required this.name,
    required this.date,
    required this.buckets,
    required this.readings,
    required this.loud,
    required this.loudInSilence,
    required this.loudestHour,
  });

  final String name;
  final String date;
  final List<HourBucket> buckets;
  final int readings;
  final int loud;
  final int loudInSilence;
  final int? loudestHour;

  factory History.fromJson(Map<String, dynamic> json) {
    final summary = _map(json['summary']);
    final loudest = summary['loudest_hour'];
    return History(
      name: _toString(json['name']) ?? '',
      date: _toString(json['date']) ?? '',
      buckets: _list(json['buckets'])
          .whereType<Map>()
          .map((item) => HourBucket.fromJson(_map(item)))
          .toList(),
      readings: _toInt(summary['readings']),
      loud: _toInt(summary['loud']),
      loudInSilence: _toInt(summary['loud_in_silence']),
      loudestHour: loudest == null ? null : _toInt(loudest),
    );
  }
}

// ---------------------------------------------
// Conta, moradores e alertas
// ---------------------------------------------

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.status,
    required this.sensorIds,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.devices,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // admin | morador
  final bool active;
  final String status; // ativo | convite_pendente | inativo
  final List<String> sensorIds;
  final bool emailEnabled;
  final bool pushEnabled;
  final int devices;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final notifications = _map(json['notifications']);
    return AppUser(
      id: _toInt(json['id']),
      name: _toString(json['name']) ?? '',
      email: _toString(json['email']) ?? '',
      phone: _toString(json['phone']),
      role: _toString(json['role']) ?? 'morador',
      active: json['active'] == true,
      status: _toString(json['status']) ?? '',
      sensorIds: _list(json['sensor_ids']).whereType<String>().toList(),
      emailEnabled: notifications['email'] == true,
      pushEnabled: notifications['push'] == true,
      devices: _toInt(json['devices']),
    );
  }
}

class Session {
  Session({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: _toString(json['token']) ?? '',
        user: AppUser.fromJson(_map(json['user'])),
      );
}

class InviteResult {
  InviteResult({required this.url, required this.channel, required this.status, required this.detail});

  final String url;
  final String channel; // email | phone
  final String status; // sent | simulated | failed | skipped
  final String detail;

  /// true somente quando o servidor realmente enviou o convite.
  bool get delivered => status == 'sent';

  factory InviteResult.fromJson(Map<String, dynamic> json) {
    final delivery = _map(json['delivery']);
    return InviteResult(
      url: _toString(json['invite_url']) ?? '',
      channel: _toString(delivery['channel']) ?? 'email',
      status: _toString(delivery['status']) ?? '',
      detail: _toString(delivery['detail']) ?? '',
    );
  }
}

class SensorInfo {
  SensorInfo({required this.sensorId, required this.label, required this.active});

  final String sensorId;
  final String label;
  final bool active;

  factory SensorInfo.fromJson(Map<String, dynamic> json) {
    final id = _toString(json['sensor_id']) ?? '';
    final display = _toString(json['display_name']);
    final location = _toString(json['location']);
    return SensorInfo(
      sensorId: id,
      label: (display != null && display.isNotEmpty)
          ? display
          : (location != null && location.isNotEmpty ? location : id),
      active: json['active'] == true,
    );
  }
}

class DeliveryInfo {
  DeliveryInfo({required this.channel, required this.status, required this.detail});

  final String channel;
  final String status;
  final String detail;

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
        channel: _toString(json['channel']) ?? '',
        status: _toString(json['status']) ?? '',
        detail: _toString(json['detail']) ?? '',
      );
}

class AlertEvent {
  AlertEvent({
    required this.houseName,
    required this.level,
    required this.createdAt,
    required this.deliveries,
  });

  final String houseName;
  final String level;
  final DateTime? createdAt;
  final List<DeliveryInfo> deliveries;

  factory AlertEvent.fromJson(Map<String, dynamic> json) => AlertEvent(
        houseName: _toString(json['house_name']) ?? (_toString(json['sensor_id']) ?? ''),
        level: _toString(json['noise_level']) ?? '',
        createdAt: DateTime.tryParse(_toString(json['created_at']) ?? '')?.toLocal(),
        deliveries: _list(json['deliveries'])
            .whereType<Map>()
            .map((item) => DeliveryInfo.fromJson(_map(item)))
            .toList(),
      );
}

/// Extrai o token de um link de convite ("...convite?token=ABC") ou devolve o
/// próprio texto quando a pessoa colou só o código.
String inviteTokenFrom(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text);
  final fromQuery = uri?.queryParameters['token'];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
  return text;
}

// ---------------------------------------------
// Cliente HTTP
// ---------------------------------------------

class ApiClient {
  ApiClient(this.baseUrl, {this.token});

  /// Ex.: http://192.168.0.10:5000
  final String baseUrl;

  /// Token da sessão (null = sem login).
  final String? token;

  bool get loggedIn => token != null && token!.isNotEmpty;

  ApiClient withToken(String? newToken) => ApiClient(baseUrl, token: newToken);

  static const _timeout = Duration(seconds: 8);

  /// Aceita "192.168.0.10", "192.168.0.10:5000" ou "http://..." e devolve
  /// sempre no formato completo, usando a porta 5000 se nenhuma for informada.
  static String normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return input.trim();
    }

    // Garante a porta 5000 do servidor local quando o usuário não informou outra.
    if (!uri.hasPort) {
      final scheme = uri.scheme;
      final host = uri.host;
      final path = uri.path.isEmpty ? '' : uri.path;
      final query = uri.query.isEmpty ? '' : '?${uri.query}';
      return '$scheme://$host:5000$path$query';
    }

    return url;
  }

  Future<Overview> overview() async {
    final json = await overviewJson();
    return Overview.fromJson(json);
  }

  Future<Map<String, dynamic>> overviewJson() => _get('/api/app/overview');

  Future<History> history(String sensorId) async {
    final json = await historyJson(sensorId);
    return History.fromJson(json);
  }

  Future<Map<String, dynamic>> historyJson(String sensorId) =>
      _get('/api/app/houses/${Uri.encodeComponent(sensorId)}/history');

  // ---------- conta ----------

  Future<Session> login(String email, String password) async {
    final json = await _json('POST', '/api/auth/login', body: {'email': email, 'password': password});
    return Session.fromJson(_map(json));
  }

  Future<void> logout() => _json('POST', '/api/auth/logout');

  Future<AppUser> me() async => AppUser.fromJson(_map(await _json('GET', '/api/auth/me')));

  Future<Session> acceptInvite(String inviteToken, String password) async {
    final json = await _json(
      'POST',
      '/api/auth/invites/accept',
      body: {'token': inviteToken, 'password': password},
    );
    return Session.fromJson(_map(json));
  }

  Future<void> setPreferences({bool? email, bool? push}) => _json(
        'PUT',
        '/api/me/preferences',
        body: {if (email != null) 'email': email, if (push != null) 'push': push},
      );

  Future<List<AlertEvent>> myAlerts() async {
    final json = await _json('GET', '/api/me/alerts');
    return _list(json).whereType<Map>().map((item) => AlertEvent.fromJson(_map(item))).toList();
  }

  /// Devolve uma linha por canal, ex.: "email: simulated — SMTP não configurado".
  Future<List<DeliveryInfo>> sendTestNotification() async {
    final json = _map(await _json('POST', '/api/me/notifications/test'));
    return _list(json['results'])
        .whereType<Map>()
        .map((item) => DeliveryInfo.fromJson(_map(item)))
        .toList();
  }

  Future<void> registerDevice(String deviceToken, String platform) => _json(
        'POST',
        '/api/me/devices',
        body: {'token': deviceToken, 'platform': platform},
      );

  // ---------- administração ----------

  Future<List<AppUser>> adminUsers() async {
    final json = await _json('GET', '/api/admin/users');
    return _list(json).whereType<Map>().map((item) => AppUser.fromJson(_map(item))).toList();
  }

  Future<List<SensorInfo>> adminSensors() async {
    final json = await _json('GET', '/api/admin/sensors');
    return _list(json).whereType<Map>().map((item) => SensorInfo.fromJson(_map(item))).toList();
  }

  Future<InviteResult> adminCreateUser({
    required String name,
    required String email,
    String? phone,
    required List<String> sensorIds,
    required bool emailEnabled,
    required bool pushEnabled,
    required String inviteChannel,
  }) async {
    final json = _map(await _json('POST', '/api/admin/users', body: {
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': 'morador',
      'sensor_ids': sensorIds,
      'notifications': {'email': emailEnabled, 'push': pushEnabled},
      'invite_channel': inviteChannel,
    }));
    return InviteResult.fromJson(_map(json['invite']));
  }

  Future<void> adminUpdateUser(int userId, Map<String, dynamic> changes) =>
      _json('PATCH', '/api/admin/users/$userId', body: changes);

  Future<InviteResult> adminResendInvite(int userId, String channel) async {
    final json = await _json('POST', '/api/admin/users/$userId/invite', body: {'channel': channel});
    return InviteResult.fromJson(_map(json));
  }

  // ---------- transporte ----------

  Future<Map<String, dynamic>> _get(String path) async {
    final decoded = await _json('GET', path);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('O servidor respondeu algo que o app não entendeu.');
  }

  /// Faz a chamada e devolve o JSON decodificado (ou null quando não há corpo).
  Future<dynamic> _json(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.tryParse('$baseUrl$path');
    if (uri == null) {
      throw ApiException('O endereço "$baseUrl" não é válido.');
    }
    final response = await _send(method, uri, body);
    final status = response.statusCode;

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        // bodyBytes + utf8 garante que acentos ("Área", "Sueli") cheguem certos
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }

    if (status == 401 && path != '/api/auth/login') {
      throw UnauthorizedException(
        loggedIn ? 'Sua sessão expirou. Entre novamente.' : 'Entre com sua conta para continuar.',
      );
    }
    if (status == 404 && path.startsWith('/api/app/overview')) {
      throw ApiException(
        'Encontrei o servidor, mas ele não tem as rotas do aplicativo. '
        'Atualize o sistema do computador para a versão 5.',
      );
    }
    if (status == 404 && (path.startsWith('/api/auth') || path == '/api/me/preferences')) {
      final detail = _detail(decoded);
      const outdated = 'Este servidor ainda não tem login. Atualize o sistema do computador.';
      throw ApiException(detail == null || detail == 'Not Found' ? outdated : detail);
    }
    if (status < 200 || status >= 300) {
      throw ApiException(_detail(decoded) ?? 'O servidor respondeu com erro $status.');
    }
    if (status == 204 || response.bodyBytes.isEmpty) return null;
    if (decoded == null) {
      throw ApiException('O servidor respondeu algo que o app não entendeu.');
    }
    return decoded;
  }

  /// Mensagem de erro do FastAPI: {"detail": "texto"} ou {"detail": [{"msg": ...}]}.
  static String? _detail(dynamic decoded) {
    if (decoded is! Map) return null;
    final detail = decoded['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List) {
      final messages = detail
          .whereType<Map>()
          .map((item) => item['msg'])
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return null;
  }

  Future<http.Response> _send(String method, Uri uri, Map<String, dynamic>? body) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (loggedIn) 'Authorization': 'Bearer $token',
    };
    final payload = body == null ? null : jsonEncode(body);
    try {
      final Future<http.Response> request;
      switch (method) {
        case 'POST':
          request = http.post(uri, headers: headers, body: payload);
        case 'PUT':
          request = http.put(uri, headers: headers, body: payload);
        case 'PATCH':
          request = http.patch(uri, headers: headers, body: payload);
        default:
          request = http.get(uri, headers: headers);
      }
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        'O servidor em $baseUrl não respondeu a tempo. '
        'Confira se o computador está ligado e no mesmo Wi-Fi do celular.',
      );
    } catch (_) {
      throw ApiException(
        'Não consegui conectar em $baseUrl. '
        'Confira o endereço e se o celular está no mesmo Wi-Fi do computador.',
      );
    }
  }
}
