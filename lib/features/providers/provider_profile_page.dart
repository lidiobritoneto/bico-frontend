import 'package:flutter/material.dart';
import '../../core/widgets/bico_card.dart';
import '../../core/widgets/bico_chip.dart';
import '../../models/bico_provider.dart';
import '../orders/create_order_page.dart';

class ProviderProfilePage extends StatelessWidget {
  final BicoProvider provider;

  const ProviderProfilePage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(provider.name);
    final theme = Theme.of(context);

    final city = (provider.city ?? '').toString();
    final state = (provider.state ?? '').toString();
    final bio = (provider.bio ?? '').toString();

    final categories = (provider.categories ?? <String>[]);

    final rating = (provider.rating ?? 0.0);
    final reviewsCount = (provider.reviewsCount ?? 0);

    final priceBase = (provider.priceBase ?? 0.0);
    final priceType = (provider.priceType ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(title: const Text("Prestador")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BicoCard(
            child: Row(
              children: [
                _Avatar(initials: initials, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        "$city - $state",
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${rating.toStringAsFixed(1)}  ($reviewsCount avaliações)",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BicoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Especializações", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                if (categories.isEmpty)
                  Text(
                    "Sem especializações cadastradas.",
                    style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.75)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) => BicoChip(label: c)).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BicoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sobre", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                Text(bio.isEmpty ? "Sem descrição." : bio),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BicoCard(
            child: Row(
              children: [
                const Icon(Icons.payments_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // ✅ R\$ para não quebrar build por causa do $
                    "Preço base: R\$ ${priceBase.toStringAsFixed(0)} ${priceType.isEmpty ? '' : priceType}",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateOrderPage(provider: provider),
                ),
              );
            },
            child: const Text("SOLICITAR SERVIÇO"),
          ),
          const SizedBox(height: 10),
          Text(
            "Pagamento: combinar no chat (MVP)",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return "?";

    final parts = n.split(RegExp(r"\s+")).where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return "?";

    final a = parts[0].isNotEmpty ? parts[0].substring(0, 1).toUpperCase() : "?";
    if (parts.length == 1) return a;

    final b = parts[1].isNotEmpty ? parts[1].substring(0, 1).toUpperCase() : "";
    return (a + b).trim().isEmpty ? a : (a + b);
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;

  const _Avatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
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
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.32),
      ),
    );
  }
}