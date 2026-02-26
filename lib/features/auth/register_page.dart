import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../home/shell_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.session});
  final Session session;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final ApiClient api;
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  String role = 'client';
  bool loading = false;
  String? err;

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
  }

  Future<void> doRegister() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final data = await api.post('/auth/register', {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'password': pass.text,
        'role': role,
      });

      final user = data['user'] as Map<String, dynamic>;
      await widget.session.setAuth(
        tokenValue: data['token'],
        userIdValue: user['id'],
        roleValue: user['role'],
        nameValue: user['name'],
        emailValue: user['email'],
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ShellPage(session: widget.session)),
        (_) => false,
      );
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha (mín. 6)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'client', label: Text('Cliente'), icon: Icon(Icons.person)),
                      ButtonSegment(value: 'provider', label: Text('Prestador'), icon: Icon(Icons.handyman)),
                    ],
                    selected: {role},
                    onSelectionChanged: (s) => setState(() => role = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : doRegister,
                      child: loading ? const CircularProgressIndicator() : const Text('Criar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}