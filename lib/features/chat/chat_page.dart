import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../../core/theme/bico_theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.session, required this.orderId});
  final Session session;
  final String orderId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ApiClient api;

  final msg = TextEditingController();
  final scroll = ScrollController();

  // ✅ foco do campo de digitação
  final FocusNode _inputFocus = FocusNode();

  bool loading = false;
  bool sending = false;
  String? err;
  List<Map<String, dynamic>> messages = const [];

  // Destaque de mensagens recebidas recentemente (borda/“glow” por alguns segundos)
  final Set<String> _seenIds = <String>{};
  final Map<String, DateTime> _highlightUntil = <String, DateTime>{};

  Timer? timer;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    fetch();

    // ✅ já abre com o foco no input (bem WhatsApp)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inputFocus.requestFocus();
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) => fetch(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    scroll.dispose();
    msg.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  DateTime? _parseCreatedAt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  void _ensureInputFocus() {
    // ✅ garante o cursor no input sem precisar clicar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_inputFocus.hasFocus) _inputFocus.requestFocus();
    });
  }

  Future<void> fetch({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        err = null;
      });
    }
    try {
      final data = await api.get('/chat/${widget.orderId}', auth: true);
      final list = (data as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      final meId = widget.session.userId;
      final now = DateTime.now();

      for (final it in list) {
        final id = (it['id'] ?? '').toString();
        if (id.isEmpty) continue;

        if (_seenIds.add(id)) {
          final sender = (it['sender'] as Map?)?.cast<String, dynamic>();
          final senderId = (sender?['id'] ?? '').toString();
          final isMe = senderId == meId;
          if (!isMe) {
            _highlightUntil[id] = now.add(const Duration(seconds: 4));
          }
        }
      }

      if (!mounted) return;
      setState(() => messages = list);

      _scrollToBottom();

      // ✅ se o usuário estava digitando, não “perde” o cursor quando chegar msg
      if (_inputFocus.hasFocus) _ensureInputFocus();
    } catch (e) {
      if (!silent && mounted) setState(() => err = e.toString());
    } finally {
      if (!silent && mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final text = msg.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
      err = null;
    });

    // ✅ limpa mas mantém o cursor no input
    msg.clear();
    _ensureInputFocus();

    try {
      await api.post('/chat/${widget.orderId}', {'content': text}, auth: true);
      await fetch(silent: true);

      // ✅ depois do envio e update do chat, mantém foco
      _ensureInputFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => err = e.toString());
      _ensureInputFocus();
    } finally {
      if (!mounted) return;
      setState(() => sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      final max = scroll.position.maxScrollExtent;
      scroll.animateTo(
        max < 0 ? 0 : max,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _bubble({
    required bool isMe,
    required bool highlight,
    required String senderName,
    required String content,
    required String timeLabel,
  }) {
    final bg = isMe ? BicoTheme.accent : BicoTheme.primary;
    final fg = isMe ? const Color(0xFF0B0F14) : Colors.white;

    final borderColor =
        highlight ? BicoTheme.accent.withOpacity(0.95) : Colors.white.withOpacity(0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: bg.withOpacity(isMe ? 0.92 : 0.86),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: BicoTheme.accent.withOpacity(0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                )
              ]
            : const [],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: fg.withOpacity(isMe ? 0.95 : 0.98),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: fg,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: fg.withOpacity(0.78),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meId = widget.session.userId;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat do Pedido')),
      body: Column(
        children: [
          if (err != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(err!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final sender = (m['sender'] as Map<String, dynamic>?) ?? const {};
                        final isMe = sender['id'] == meId;

                        final id = (m['id'] ?? '').toString();
                        final until = _highlightUntil[id];
                        final highlight = !isMe && until != null && until.isAfter(now);

                        final createdAt = _parseCreatedAt(m['createdAt']);
                        final timeLabel = createdAt == null ? '' : _fmt.format(createdAt);

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: _bubble(
                            isMe: isMe,
                            highlight: highlight,
                            senderName: (sender['name'] ?? '').toString(),
                            content: (m['content'] ?? '').toString(),
                            timeLabel: timeLabel,
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _inputFocus, // ✅ aqui
                      controller: msg,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem…',
                        prefixIcon: const Icon(Icons.message_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            msg.clear();
                            _ensureInputFocus();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      onSubmitted: (_) => send(),
                      onTap: _ensureInputFocus,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: FilledButton(
                      onPressed: sending ? null : send,
                      style: FilledButton.styleFrom(
                        backgroundColor: BicoTheme.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}