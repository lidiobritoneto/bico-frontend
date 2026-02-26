import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../../core/utils/avatar_picker.dart';
import '../../core/widgets/bico_avatar.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.session});
  final Session session;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final ApiClient api;

  final name = TextEditingController();
  final phone = TextEditingController();

  String? avatarBase64;

  bool saving = false;
  String? err;

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    name.text = widget.session.name ?? '';
    phone.text = widget.session.phone ?? '';
    avatarBase64 = widget.session.avatarBase64;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> pickAvatar() async {
    final b64 = await AvatarPicker.pickImageAsBase64();
    if (!mounted) return;
    if (b64 == null) return;
    setState(() => avatarBase64 = b64);
  }

  Future<void> save() async {
    if (saving) return;

    setState(() {
      saving = true;
      err = null;
    });

    try {
      final payload = <String, dynamic>{
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'avatarBase64': (avatarBase64 ?? '').trim(),
      };

      final me = await api.patch('/users/me', body: payload, auth: true);

      await widget.session.setProfile(
        nameValue: (me['name'] ?? '').toString(),
        phoneValue: (me['phone'] ?? '').toString(),
        avatarBase64Value: (me['avatarBase64'] ?? '').toString(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inits = _initials(name.text.isEmpty ? (widget.session.name ?? '') : name.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: saving ? null : save,
            child: saving ? const Text('Salvando…') : const Text('Salvar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(err!, style: const TextStyle(color: Colors.red)),
                  ),
                Row(
                  children: [
                    BicoAvatar(initials: inits, size: 72, avatarBase64: avatarBase64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Foto do perfil', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: pickAvatar,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Escolher'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => avatarBase64 = null),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remover'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Dica'),
                    subtitle: const Text('A foto fica salva no seu dispositivo (base64) e também no servidor (MVP).'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
