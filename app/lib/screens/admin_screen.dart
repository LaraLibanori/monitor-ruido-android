import 'package:flutter/material.dart';

import '../noise_ui.dart';
import '../settings.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Resident> _residents = <Resident>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final residents = await Settings.loadResidents();
    if (mounted) setState(() => _residents = residents);
  }

  Future<void> _addResident() async {
    final resident = await showDialog<Resident>(
      context: context,
      builder: (_) => const _ResidentDialog(),
    );
    if (resident == null) return;
    final residents = [..._residents, resident];
    await Settings.saveResidents(residents);
    if (mounted) setState(() => _residents = residents);
  }

  Future<void> _removeResident(Resident resident) async {
    final residents = _residents.where((item) => item.id != resident.id).toList();
    await Settings.saveResidents(residents);
    if (mounted) setState(() => _residents = residents);
  }

  Future<void> _toggleResident(Resident resident, bool enabled) async {
    final residents = _residents
        .map((item) => item.id == resident.id
            ? Resident(
                id: item.id,
                name: item.name,
                contact: item.contact,
                channel: item.channel,
                house: item.house,
                enabled: enabled,
              )
            : item)
        .toList();
    await Settings.saveResidents(residents);
    if (mounted) setState(() => _residents = residents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addResident,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Adicionar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moradores que recebem alertas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.night),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta tela salva uma configuração local para demonstração. '
                  'O cadastro seguro, convite, login e envio real por e-mail ou push '
                  'dependem do backend autenticado.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_residents.isEmpty)
            const SoftCard(
              child: Text(
                'Nenhum morador cadastrado. Use Adicionar para configurar um destinatário.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          for (final resident in _residents)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(resident.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${resident.channel == 'email' ? 'E-mail' : 'Telefone'}: ${resident.contact}\nCasa: ${resident.house}',
                            style: const TextStyle(color: AppColors.muted, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: resident.enabled,
                      onChanged: (value) => _toggleResident(resident, value),
                    ),
                    IconButton(
                      tooltip: 'Remover morador',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeResident(resident),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResidentDialog extends StatefulWidget {
  const _ResidentDialog();

  @override
  State<_ResidentDialog> createState() => _ResidentDialogState();
}

class _ResidentDialogState extends State<_ResidentDialog> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _house = TextEditingController();
  String _channel = 'email';

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _house.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    final house = _house.text.trim();
    if (name.isEmpty || contact.isEmpty || house.isEmpty) return;
    Navigator.of(context).pop(
      Resident(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        contact: contact,
        channel: _channel,
        house: house,
        enabled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo morador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
              controller: _contact,
              decoration: InputDecoration(
                labelText: _channel == 'email' ? 'E-mail' : 'Telefone',
              ),
              keyboardType: _channel == 'email' ? TextInputType.emailAddress : TextInputType.phone,
            ),
            TextField(controller: _house, decoration: const InputDecoration(labelText: 'Casa/sensor')),
            DropdownButtonFormField<String>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Canal preferido'),
              items: const [
                DropdownMenuItem(value: 'email', child: Text('E-mail')),
                DropdownMenuItem(value: 'phone', child: Text('Telefone')),
              ],
              onChanged: (value) => setState(() => _channel = value ?? 'email'),
            ),
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
