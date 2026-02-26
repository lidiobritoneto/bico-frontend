import 'package:flutter/material.dart';
import '../../core/session/session.dart';
import '../orders/orders_page.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    // Simplão: chat é por pedido. Então essa aba aponta pro "Pedidos" (chat dentro).
    return OrdersPage(session: session, asProviderDashboard: false);
  }
}