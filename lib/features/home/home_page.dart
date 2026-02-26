import 'package:flutter/material.dart';
import '../../core/widgets/bico_card.dart';
import '../../core/widgets/bico_chip.dart';
import '../../data/mock/mock_repo.dart';
import '../../models/bico_provider.dart';
import 'provider_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _city = "São Luís";
  String _state = "MA";
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final providers = MockRepo.searchProviders(
      city: _city,
      state: _state,
      categoryName: _selectedCategory,
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text(
            "BICO",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            )
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local
                BicoCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Local de busca", style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: "Cidade",
                                    ),
                                    controller: TextEditingController(text: _city),
                                    onChanged: (v) => _city = v,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 84,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: "UF",
                                    ),
                                    controller: TextEditingController(text: _state),
                                    onChanged: (v) => _state = v,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text("Buscar"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Categorias",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: Text(_selectedCategory == null ? "Todas" : "Todas"),
                      onPressed: () => setState(() => _selectedCategory = null),
                    ),
                    ...MockRepo.categories.map((c) {
                      final selected = _selectedCategory == c.name;
                      return ChoiceChip(
                        label: Text(c.name),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = c.name),
                      );
                    })
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  "Prestadores em ${_city.trim().isEmpty ? "sua cidade" : _city} - ${_state.trim().isEmpty ? "UF" : _state}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        if (providers.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Nenhum prestador encontrado nesse local/filtro.\nTente outra cidade/UF ou remova o filtro de categoria.",
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: providers.length,
            itemBuilder: (context, i) => _ProviderTile(
              provider: providers[i],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfilePage(provider: providers[i]),
                  ),
                );
              },
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final BicoProvider provider;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: BicoCard(
        onTap: onTap,
        child: Row(
          children: [
            _Avatar(initials: _initials(provider.name)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("${provider.city} - ${provider.state}",
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: provider.categories.take(2).map((c) => BicoChip(label: c)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(provider.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "R\$ ${provider.priceBase.toStringAsFixed(0)} ${provider.priceType}",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.9),
            cs.secondary.withOpacity(0.9),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}