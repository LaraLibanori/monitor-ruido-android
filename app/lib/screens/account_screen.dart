// =============================================
// account_screen.dart - Minha conta: alertas, preferências e saída
// =============================================

import 'package:flutter/material.dart';

import '../api.dart';
import '../noise_ui.dart';
import '../session.dart';
import '../settings.dart';
import 'admin_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

const _statusLabels = <String, String>{
  'sent': 'enviado',
  'simulated': 'simulado (servidor sem credenciais)',
  'failed': 'falhou',
  'skipped': 'não enviado',
};

String deliveryLabel(DeliveryInfo delivery) {
  final channel = delivery.channel == 'push' ? 'Push' : 'E-mail';
  final status = _statusLabels[delivery.status] ?? delivery.status;
  return '$channel: $status';
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AppUser? _user;
  List<AlertEvent> _alerts = const <AlertEvent>[];
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await widget.api.me();
      final alerts = await widget.api.myAlerts();
      if (!mounted) return;
      setState(() {
        _user = user;
        _alerts = alerts;
        _error = null;
      });
    } on UnauthorizedException catch (e) {
      await _sessionEnded(e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _sessionEnded(String message) async {
    await SessionStore.clear();
    await Settings.clearCache();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(api: widget.api.withToken(null), message: message, mandatory: true),
      ),
      (route) => false,
    );
  }

  Future<void> _setPreference({bool? email, bool? push}) async {
    setState(() => _saving = true);
    try {
      await widget.api.setPreferences(email: email, push: push);
      await _load();
    } on UnauthorizedException catch (e) {
      await _sessionEnded(e.message);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() => _saving = true);
    try {
      final results = await widget.api.sendTestNotification();
      _showMessage(results.map(deliveryLabel).join('\n'));
    } on UnauthorizedException catch (e) {
      await _sessionEnded(e.message);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.api.logout();
    } on ApiException {
      // Sem conexão: sai localmente mesmo assim.
    }
    await SessionStore.clear();
    await Settings.clearCache();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => HomeScreen(api: widget.api.withToken(null))),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _when(DateTime? moment) {
    if (moment == null) return '';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(moment.day)}/${two(moment.month)} ${two(moment.hour)}:${two(moment.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: user == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error, textAlign: TextAlign.center),
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.night,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.email}\n${user.isAdmin ? 'Administrador' : 'Morador'}',
                          style: const TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (user.isAdmin) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => AdminScreen(api: widget.api)),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Administrar moradores'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alertas no horário de silêncio',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.night),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notificação no celular'),
                          subtitle: Text(
                            user.devices > 0
                                ? '${user.devices} aparelho(s) registrado(s).'
                                : 'Nenhum aparelho registrado: o push depende do Firebase '
                                    'configurado neste app e no servidor.',
                          ),
                          value: user.pushEnabled,
                          onChanged: _saving ? null : (value) => _setPreference(push: value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('E-mail'),
                          subtitle: Text(user.email),
                          value: user.emailEnabled,
                          onChanged: _saving ? null : (value) => _setPreference(email: value),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _saving ? null : _sendTest,
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: const Text('Enviar alerta de teste'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alertas recentes',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.night),
                        ),
                        const SizedBox(height: 8),
                        if (_alerts.isEmpty)
                          const Text('Nenhum alerta ainda.', style: TextStyle(color: AppColors.muted)),
                        for (final alert in _alerts.take(10))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_when(alert.createdAt)} · ${alert.houseName} · '
                                  '${alert.level == 'muito_alto' ? 'muito alto' : alert.level}',
                                ),
                                for (final delivery in alert.deliveries)
                                  Text(
                                    deliveryLabel(delivery),
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                  ),
                ],
              ),
            ),
    );
  }
}
