// =============================================
// admin_screen.dart - Administrador: moradores, casas e convites
// =============================================
// Tudo aqui é gravado no servidor (rotas /api/admin). O servidor só aceita
// essas chamadas de uma conta com papel "admin".
// =============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../noise_ui.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<AppUser> _users = const <AppUser>[];
  List<SensorInfo> _sensors = const <SensorInfo>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await widget.api.adminUsers();
      final sensors = await widget.api.adminSensors();
      if (!mounted) return;
      setState(() {
        _users = users;
        _sensors = sensors;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _sensorLabel(String sensorId) {
    for (final sensor in _sensors) {
      if (sensor.sensorId == sensorId) return sensor.label;
    }
    return sensorId;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addResident() async {
    final draft = await showDialog<ResidentDraft>(
      context: context,
      builder: (_) => _ResidentDialog(sensors: _sensors),
    );
    if (draft == null) return;
    try {
      final invite = await widget.api.adminCreateUser(
        name: draft.name,
        email: draft.email,
        phone: draft.phone,
        sensorIds: draft.sensorIds,
        emailEnabled: draft.emailEnabled,
        pushEnabled: draft.pushEnabled,
        inviteChannel: 'email',
      );
      await _load();
      _showInvite(draft.email, invite);
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _toggleActive(AppUser user, bool active) async {
    try {
      await widget.api.adminUpdateUser(user.id, {'active': active});
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _resendInvite(AppUser user) async {
    try {
      final invite = await widget.api.adminResendInvite(user.id, 'email');
      await _load();
      _showInvite(user.email, invite);
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  void _showInvite(String email, InviteResult invite) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Convite'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invite.delivered
                    ? 'Convite enviado por e-mail para $email.'
                    : 'O servidor não enviou o e-mail (envio não configurado ou com falha). '
                        'Copie o link abaixo e envie para $email.',
              ),
              const SizedBox(height: 12),
              SelectableText(invite.url, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invite.url));
              Navigator.of(dialogContext).pop();
              _showMessage('Link copiado.');
            },
            child: const Text('Copiar link'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _details(AppUser user) {
    final houses = user.sensorIds.map(_sensorLabel).join(', ');
    final channels = <String>[
      if (user.pushEnabled) 'push',
      if (user.emailEnabled) 'e-mail',
    ];
    final lines = <String>[
      user.email,
      user.sensorIds.isEmpty ? 'Nenhuma casa vinculada' : 'Casas: $houses',
      channels.isEmpty ? 'Alertas: desligados' : 'Alertas: ${channels.join(' e ')}',
    ];
    return lines.join('\n');
  }

  static String _statusText(AppUser user) {
    switch (user.status) {
      case 'ativo':
        return 'Ativo';
      case 'convite_pendente':
        return 'Convite pendente';
      default:
        return 'Inativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      floatingActionButton: _loading || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addResident,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Adicionar'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (error != null)
                    SoftCard(child: Text(error, style: const TextStyle(color: AppColors.alert))),
                  if (error == null)
                    const SoftCard(
                      child: Text(
                        'Moradores recebem alertas das casas vinculadas a eles. '
                        'Sensores, horário de silêncio e histórico de envios ficam no '
                        'painel do computador (endereço do servidor + /admin).',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ),
                  const SizedBox(height: 12),
                  for (final user in _users)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.isAdmin ? '${user.name} (admin)' : user.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  _statusText(user),
                                  style: TextStyle(
                                    color: user.status == 'ativo' ? AppColors.night : AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _details(user),
                              style: const TextStyle(color: AppColors.muted, height: 1.35),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (user.status == 'convite_pendente')
                                  TextButton(
                                    onPressed: () => _resendInvite(user),
                                    child: const Text('Novo convite'),
                                  ),
                                if (!user.isAdmin)
                                  TextButton(
                                    onPressed: () => _toggleActive(user, !user.active),
                                    child: Text(user.active ? 'Desativar' : 'Reativar'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Dados digitados no formulário de novo morador.
class ResidentDraft {
  const ResidentDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.sensorIds,
    required this.emailEnabled,
    required this.pushEnabled,
  });

  final String name;
  final String email;
  final String? phone;
  final List<String> sensorIds;
  final bool emailEnabled;
  final bool pushEnabled;

  /// Mensagem do primeiro problema encontrado, ou null se está tudo certo.
  static String? validate({required String name, required String email}) {
    if (name.trim().isEmpty) return 'Informe o nome.';
    final value = email.trim();
    final at = value.indexOf('@');
    if (at <= 0 || !value.substring(at + 1).contains('.') || value.contains(' ')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }
}

class _ResidentDialog extends StatefulWidget {
  const _ResidentDialog({required this.sensors});

  final List<SensorInfo> sensors;

  @override
  State<_ResidentDialog> createState() => _ResidentDialogState();
}

class _ResidentDialogState extends State<_ResidentDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _selected = <String>{};
  bool _push = true;
  bool _mail = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final problem = ResidentDraft.validate(name: _name.text, email: _email.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final phone = _phone.text.trim();
    Navigator.of(context).pop(
      ResidentDraft(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: phone.isEmpty ? null : phone,
        sensorIds: _selected.toList()..sort(),
        emailEnabled: _mail,
        pushEnabled: _push,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AlertDialog(
      title: const Text('Novo morador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
              controller: _email,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail (recebe o convite)'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
            ),
            const SizedBox(height: 14),
            const Text('Casas', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final sensor in widget.sensors)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(sensor.label),
                value: _selected.contains(sensor.sensorId),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selected.add(sensor.sensorId);
                  } else {
                    _selected.remove(sensor.sensorId);
                  }
                }),
              ),
            const SizedBox(height: 8),
            const Text('Alertas por', style: TextStyle(fontWeight: FontWeight.w700)),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Notificação no celular'),
              value: _push,
              onChanged: (value) => setState(() => _push = value),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('E-mail'),
              value: _mail,
              onChanged: (value) => setState(() => _mail = value),
            ),
            if (error != null) Text(error, style: const TextStyle(color: AppColors.alert)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
