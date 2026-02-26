import 'package:flutter/material.dart';
import '../../core/session/session.dart';
import '../auth/login_page.dart';
import '../profile/provider_professional_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final role = session.role ?? '-';
    final isProvider = role == 'provider';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/bico_logo.png',
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    session.name ?? '—',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(session.email ?? '—'),
                  Text('Perfil: $role'),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isProvider)
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Perfil profissional'),
                subtitle: const Text('Qualificações, preço, cidade e bio'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProviderProfessionalPage(session: session)),
                  );
                },
              ),
            ),

          if (isProvider) const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await session.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginPage(session: session)),
                    (_) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}