import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../../models/bico_provider.dart';
import '../orders/create_order_page.dart';
import '../../core/widgets/uf_city_search_picker.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key, required this.session});
  final Session session;

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  late final ApiClient api;
  final city = TextEditingController();
  final state = TextEditingController();
  int? cityId;
  String? ufSigla;
  final category = TextEditingController();

  bool loading = false;
  String? err;

  List<BicoProvider> providers = const [];

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    // Defaults (pode mudar pelo combo)
    city.text = 'São Luís';
    state.text = 'MA';
    ufSigla = 'MA';
    fetch();
  }

  @override
  void dispose() {
    city.dispose();
    state.dispose();
    category.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final q = <String, String>{};
      final cityText = city.text.trim();
      final stateText = state.text.trim();
      if (cityId != null) {
        q['cityId'] = cityId.toString();
        // mantém UF pra consistência (backend pode usar/validar)
        if (ufSigla != null && ufSigla!.trim().isNotEmpty) q['state'] = ufSigla!.trim();
      } else {
        if (cityText.isNotEmpty) q['city'] = cityText;
        if (stateText.isNotEmpty) q['state'] = stateText;
      }
      final cat = category.text.trim();
      if (cat.isNotEmpty) q['category'] = cat;

      final data = await api.get('/providers', query: q);

      final list = (data as List).map((e) => BicoProvider.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => providers = list);
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _leadingAvatar(BicoProvider p) {
    final b64 = p.avatarBase64;
    if (b64 != null && b64.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        return CircleAvatar(backgroundImage: MemoryImage(bytes));
      } catch (_) {
        // cai no fallback
      }
    }

    final initials = _initials(p.name);
    return CircleAvatar(child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w900)));
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UfCitySearchPicker(
  initialUfSigla: ufSigla ?? state.text.trim(),
  initialCityId: cityId,
  initialCityName: city.text.trim().isNotEmpty ? city.text.trim() : null,
  onChanged: (picked) {
    setState(() {
      if (picked == null) {
        cityId = null;
        ufSigla = null;
      } else {
        cityId = picked.city.id;
        ufSigla = picked.uf.sigla;
        // mantém texto preenchido pra exibir e pra tela de criar pedido
        city.text = picked.city.nome;
        state.text = picked.uf.sigla;
      }
    });
  },
),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Categoria (opcional)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: loading ? null : fetch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: providers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = providers[i];
                      final cats = p.categories.join(', ');

                      return Card(
                        child: ListTile(
                          leading: _leadingAvatar(p),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${p.city}/${p.state}\n$cats\nR\$ ${p.priceBase.toStringAsFixed(0)} ${p.priceType}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateOrderPage(
                                  session: widget.session,
                                  providerUserId: p.id,
                                  providerName: p.name,
                                  city: city.text.trim(),
                                  state: state.text.trim(),
                                  defaultCategory: p.categories.isNotEmpty ? p.categories.first : '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}