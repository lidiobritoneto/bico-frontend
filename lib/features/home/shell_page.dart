import 'package:flutter/material.dart';
import '../../core/session/session.dart';
import '../providers/providers_page.dart';
import '../orders/orders_page.dart';
import '../chat/chats_page.dart';
import 'profile_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.session});
  final Session session;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.session.role == 'provider';

    final pages = <Widget>[
      isProvider ? OrdersPage(session: widget.session, asProviderDashboard: true) : ProvidersPage(session: widget.session),
      OrdersPage(session: widget.session, asProviderDashboard: false),
      ChatsPage(session: widget.session),
      ProfilePage(session: widget.session),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: Icon(isProvider ? Icons.dashboard : Icons.search),
            label: isProvider ? 'Dashboard' : 'Buscar',
          ),
          const NavigationDestination(icon: Icon(Icons.assignment), label: 'Pedidos'),
          const NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          const NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}