import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.session,
    required this.providerUserId,
    required this.providerName,
    required this.city,
    required this.state,
    required this.defaultCategory,
  });

  final Session session;
  final String providerUserId;
  final String providerName;
  final String city;
  final String state;
  final String defaultCategory;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  late final ApiClient api;
  late final TextEditingController category;
  final desc = TextEditingController();
  bool loading = false;
  String? err;

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
    category = TextEditingController(text: widget.defaultCategory);
  }

  Future<void> create() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      await api.post('/orders', {
        'providerUserId': widget.providerUserId,
        'categoryName': category.text.trim(),
        'description': desc.text.trim(),
        'city': widget.city,
        'state': widget.state,
      }, auth: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido criado!')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedir serviço • ${widget.providerName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: desc,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Descreva o problema', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : create,
                child: loading ? const CircularProgressIndicator() : const Text('Criar pedido'),
              ),
            )
          ],
        ),
      ),
    );
  }
}