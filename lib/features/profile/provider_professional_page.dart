import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../../core/utils/avatar_picker.dart';
import '../../core/widgets/bico_card.dart';
import '../../core/widgets/bico_chip.dart';
import '../../core/widgets/uf_city_combo.dart';

class ProviderProfessionalPage extends StatefulWidget {
  const ProviderProfessionalPage({super.key, required this.session});
  final Session session;

  @override
  State<ProviderProfessionalPage> createState() => _ProviderProfessionalPageState();
}

class _ProviderProfessionalPageState extends State<ProviderProfessionalPage> {
  late final ApiClient api;

  final city = TextEditingController();
  final uf = TextEditingController();
  final bio = TextEditingController();
  final priceBase = TextEditingController(text: '100');
  final priceType = TextEditingController(text: 'por serviço');
  final radius = TextEditingController(text: '10');

  final categoryInput = TextEditingController();
  final List<String> categories = [];

  String? avatarBase64;

  UfCityResult? ufCitySel;
  String? _initialUfSigla;
  String? _initialCityName;
  int? _initialCityId;

  bool loading = false;
  String? err;

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    loadProfile();
  }

  @override
  void dispose() {
    city.dispose();
    uf.dispose();
    bio.dispose();
    priceBase.dispose();
    priceType.dispose();
    radius.dispose();
    categoryInput.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      err = null;
    });

    try {
      final data = await api.get('/providers/me/profile', auth: true) as Map<String, dynamic>;

      city.text = (data['city'] ?? '').toString();
      uf.text = (data['state'] ?? '').toString();
      final cid = data['cityId'];
      _initialCityId = (cid is int) ? cid : int.tryParse((cid ?? '').toString());
      _initialCityName = city.text.trim().isEmpty ? null : city.text.trim();
      final st = uf.text.trim();
      _initialUfSigla = st.length == 2 ? st.toUpperCase() : null;
      bio.text = (data['bio'] ?? '').toString();
      priceBase.text = (data['priceBase'] ?? 0).toString();
      priceType.text = (data['priceType'] ?? 'por serviço').toString();
      radius.text = (data['serviceRadiusKm'] ?? 10).toString();

      avatarBase64 = (data['avatarBase64'] ?? '').toString();
      if (avatarBase64 != null && avatarBase64!.trim().isEmpty) avatarBase64 = null;

      categories
        ..clear()
        ..addAll(((data['categories'] ?? []) as List).map((e) => e.toString()));
    } catch (e) {
      // Se ainda não existir perfil, ok (o usuário vai preencher)
      err = null;
    } finally {
      setState(() => loading = false);
    }
  }

  void addCategory() {
    final text = categoryInput.text.trim();
    if (text.isEmpty) return;
    if (categories.any((c) => c.toLowerCase() == text.toLowerCase())) {
      categoryInput.clear();
      return;
    }
    setState(() {
      categories.add(text);
      categoryInput.clear();
    });
  }

  void removeCategory(String c) => setState(() => categories.remove(c));

  Future<void> pickPhoto() async {
    final b64 = await AvatarPicker.pickImageAsBase64();
    if (b64 == null) return;

    setState(() => avatarBase64 = b64);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto selecionada. Clique em Salvar.')),
      );
    }
  }

  Future<void> save() async {
    if ((widget.session.role ?? '') != 'provider') {
      setState(() => err = 'Somente prestador pode salvar perfil profissional.');
      return;
    }
    if (city.text.trim().isEmpty || uf.text.trim().isEmpty) {
      setState(() => err = 'Informe cidade e UF.');
      return;
    }
    if (categories.isEmpty) {
      setState(() => err = 'Adicione pelo menos 1 qualificação/categoria.');
      return;
    }

    setState(() {
      loading = true;
      err = null;
    });

    try {
      final body = <String, dynamic>{
        'city': city.text.trim(),
        if (ufCitySel != null) 'cityId': ufCitySel!.cityId,
        'state': uf.text.trim().toUpperCase(),
        'bio': bio.text.trim(),
        'serviceRadiusKm': int.tryParse(radius.text.trim()) ?? 10,
        'priceBase': double.tryParse(priceBase.text.trim().replaceAll(',', '.')) ?? 0,
        'priceType': priceType.text.trim().isEmpty ? 'por serviço' : priceType.text.trim(),
        'isActive': true,
        'categories': categories,
        if (avatarBase64 != null && avatarBase64!.trim().isNotEmpty) 'avatarBase64': avatarBase64,
      };

      await api.post('/providers/me', body, auth: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil profissional salvo!')));
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _avatar() {
    if (avatarBase64 == null || avatarBase64!.isEmpty) {
      return const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34));
    }
    try {
      final bytes = base64Decode(avatarBase64!);
      return CircleAvatar(radius: 34, backgroundImage: MemoryImage(bytes));
    } catch (_) {
      return const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = (widget.session.role ?? '') == 'provider';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil profissional')),
      body: SafeArea(
        child: !isProvider
            ? const Center(child: Text('Somente prestador pode acessar.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BicoCard(
                    child: Row(
                      children: [
                        _avatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.name ?? 'Prestador',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Foto do perfil / Qualificações',
                                style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: loading ? null : pickPhoto,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Foto'),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  UfCityCombo(
  initialUfSigla: _initialUfSigla,
  initialCityId: _initialCityId,
  initialCityName: _initialCityName,
  onChanged: (v) {
    setState(() => ufCitySel = v);
    if (v != null) {
      city.text = v.cityNome;
      uf.text = v.ufSigla;
    }
  },
),
const SizedBox(height: 12),

                  TextField(
                    controller: bio,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio / Sobre', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceBase,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Preço base (R\$)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceType,
                          decoration: const InputDecoration(labelText: 'Tipo (por hora/serviço)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: radius,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Raio (km)', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 16),

                  const Text('Qualificações / Categorias', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: categoryInput,
                          decoration: const InputDecoration(labelText: 'Ex: Eletricista', border: OutlineInputBorder()),
                          onSubmitted: (_) => addCategory(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: addCategory,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map((c) => BicoChip(label: c))
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                  if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : save,
                      child: loading ? const CircularProgressIndicator() : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}