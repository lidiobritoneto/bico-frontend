import 'package:flutter/material.dart';
import '../../core/widgets/bico_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BicoCard(
            child: Row(
              children: [
                _Avatar(initials: "CJ"),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cliente", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Modo MVP (sem login real ainda)"),
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
                const Text("Configurações", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                _RowItem(icon: Icons.security_outlined, label: "Privacidade"),
                _RowItem(icon: Icons.help_outline_rounded, label: "Ajuda"),
                _RowItem(icon: Icons.info_outline_rounded, label: "Sobre o BICO"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RowItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(colors: [cs.primary.withOpacity(0.9), cs.secondary.withOpacity(0.9)]),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}