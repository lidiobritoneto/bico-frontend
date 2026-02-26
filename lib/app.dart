import 'package:flutter/material.dart';
import '../core/session/session.dart';
import '../features/auth/login_page.dart';
import '../features/home/shell_page.dart';

class BicoApp extends StatefulWidget {
  const BicoApp({super.key});

  @override
  State<BicoApp> createState() => _BicoAppState();
}

class _BicoAppState extends State<BicoApp> {
  final _session = Session();

  @override
  void initState() {
    super.initState();
    _session.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bico',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A35FF)),
          ),
          home: _session.isReady
              ? (_session.isLoggedIn ? ShellPage(session: _session) : LoginPage(session: _session))
              : const _Splash(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/bico_logo.png', width: 96, height: 96),
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
        ]),
      ),
    );
  }
}