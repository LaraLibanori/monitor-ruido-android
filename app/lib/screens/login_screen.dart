// =============================================
// login_screen.dart - Entrar na conta ou ativar um convite
// =============================================

import 'package:flutter/material.dart';

import '../api.dart';
import '../noise_ui.dart';
import '../session.dart';
import '../settings.dart';
import 'connect_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, this.message, this.mandatory = false});

  /// Cliente sem token, apontando para o servidor escolhido.
  final ApiClient api;

  /// Aviso no topo (ex.: "Sua sessão expirou").
  final String? message;

  /// true quando o servidor só mostra as casas depois do login.
  final bool mandatory;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  final _newPassword = TextEditingController();
  bool _inviteMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final String? problem;
    if (_inviteMode) {
      problem = _invite.text.trim().isEmpty
          ? 'Cole o link do convite que você recebeu.'
          : (_newPassword.text.length < 8 ? 'A senha precisa ter pelo menos 8 caracteres.' : null);
    } else {
      problem = _email.text.trim().isEmpty || _password.text.isEmpty
          ? 'Informe e-mail e senha.'
          : null;
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = _inviteMode
          ? await widget.api.acceptInvite(inviteTokenFrom(_invite.text), _newPassword.text)
          : await widget.api.login(_email.text.trim(), _password.text);
      await SessionStore.saveToken(session.token);
      await Settings.clearCache(); // não mostrar dados em cache de outra conta
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(api: widget.api.withToken(session.token)),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeServer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ConnectScreen(initialUrl: widget.api.baseUrl)),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? helper}) => InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = widget.message;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Ruído'),
        actions: [
          IconButton(
            tooltip: 'Trocar servidor',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _changeServer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            _inviteMode ? 'Ativar convite' : 'Entrar',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.night),
          ),
          const SizedBox(height: 8),
          Text(
            _inviteMode
                ? 'Cole o link que o administrador enviou e crie sua senha.'
                : 'Use o e-mail e a senha da sua conta para ver as suas casas e receber alertas.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            SoftCard(child: Text(message, style: const TextStyle(color: AppColors.night))),
          ],
          const SizedBox(height: 20),
          if (_inviteMode) ...[
            TextField(
              controller: _invite,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: _decoration('Link ou código do convite', Icons.link),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newPassword,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: _decoration('Crie uma senha', Icons.lock_outline, helper: 'Mínimo de 8 caracteres.'),
            ),
          ] else ...[
            TextField(
              controller: _email,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: _decoration('E-mail', Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: _decoration('Senha', Icons.lock_outline),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.alert)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Aguarde...' : (_inviteMode ? 'Ativar acesso' : 'Entrar')),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _inviteMode = !_inviteMode;
                      _error = null;
                    }),
            child: Text(_inviteMode ? 'Já tenho senha' : 'Recebi um convite'),
          ),
          if (!widget.mandatory)
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Agora não'),
            ),
        ],
      ),
    );
  }
}
