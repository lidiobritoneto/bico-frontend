import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../../core/theme/bico_theme.dart';
import '../chat/chat_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.session, required this.asProviderDashboard});
  final Session session;
  final bool asProviderDashboard;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final ApiClient api;

  bool loading = false;
  String? err;
  List<Map<String, dynamic>> items = const [];

  // polling + destaque quando chega msg nova (unreadCount aumenta)
  Timer? _timer;
  final Map<String, int> _prevUnread = <String, int>{};
  final Map<String, DateTime> _highlightUntil = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    fetch();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => fetch(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetch({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        err = null;
      });
    }
    try {
      final data = await api.get('/orders/my', auth: true);
      final list = (data as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      final now = DateTime.now();
      for (final o in list) {
        final id = (o['id'] ?? '').toString();
        final unread = (o['unreadCount'] ?? 0) is int ? (o['unreadCount'] ?? 0) as int : int.tryParse((o['unreadCount'] ?? 0).toString()) ?? 0;

        final prev = _prevUnread[id] ?? 0;
        _prevUnread[id] = unread;

        // Se aumentou e é > 0, destaque por alguns segundos
        if (unread > prev && unread > 0) {
          _highlightUntil[id] = now.add(const Duration(seconds: 5));
        }
      }

      if (!mounted) return;
      setState(() => items = list);
    } catch (e) {
      if (!silent && mounted) setState(() => err = e.toString());
    } finally {
      if (!silent && mounted) setState(() => loading = false);
    }
  }

  Future<void> accept(String id) async {
    await api.patch('/orders/$id/accept', auth: true);
    await fetch(silent: true);
  }

  Future<void> refuse(String id) async {
    await api.patch('/orders/$id/refuse', auth: true);
    await fetch(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.session.role == 'provider';
    final title = widget.asProviderDashboard
        ? 'Dashboard'
        : (isProvider ? 'Meus serviços' : 'Meus pedidos');

    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: () => fetch(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        if (err != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(err!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final id = (o['id'] ?? '').toString();
                    final status = (o['status'] ?? '').toString();
                    final unreadCount = (o['unreadCount'] ?? 0) is int
                        ? (o['unreadCount'] ?? 0) as int
                        : int.tryParse((o['unreadCount'] ?? 0).toString()) ?? 0;

                    final who = isProvider ? o['client'] : o['provider'];
                    final whoName = (who is Map ? (who['name'] ?? '') : '').toString();

                    final until = _highlightUntil[id];
                    final highlight = until != null && until.isAfter(now);

                    Color statusColor(String s) {
                      switch (s) {
                        case 'new':
                          return BicoTheme.accent;
                        case 'accepted':
                        case 'in_progress':
                          return BicoTheme.primary;
                        case 'done':
                          return BicoTheme.success;
                        case 'canceled':
                          return Colors.redAccent;
                        default:
                          return BicoTheme.textMuted;
                      }
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: highlight
                            ? [
                                BoxShadow(
                                  color: BicoTheme.accent.withOpacity(0.16),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                )
                              ]
                            : const [],
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o['categoryName']?.toString() ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor(status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: statusColor(status).withOpacity(0.45)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: statusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Com: $whoName',
                                      style: const TextStyle(color: BicoTheme.textMuted, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ChatPage(session: widget.session, orderId: id),
                                            ),
                                          );
                                          // ao voltar do chat, atualiza para limpar badge
                                          await fetch(silent: true);
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: const Text('Chat'),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: BicoTheme.accent,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                o['description']?.toString() ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isProvider && widget.asProviderDashboard && status == 'new') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => accept(id),
                                        child: const Text('Aceitar'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => refuse(id),
                                        child: const Text('Recusar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
