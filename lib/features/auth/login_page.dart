import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../home/shell_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});
  final Session session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final ApiClient api;
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  String? err;

  @override
  void initState() {
    super.initState();
    api = ApiClient(widget.session);
  }

  Future<void> doLogin() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final data = await api.post('/auth/login', {
        'email': email.text.trim(),
        'password': pass.text,
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ShellPage(session: widget.session)));
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/bico_logo.png', width: 92, height: 92),
                  const SizedBox(height: 12),
                  const Text('BICO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  if (err != null)
                    Text(err!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : doLogin,
                      child: loading ? const CircularProgressIndicator() : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(session: widget.session)));
                    },
                    child: const Text('Criar conta'),
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