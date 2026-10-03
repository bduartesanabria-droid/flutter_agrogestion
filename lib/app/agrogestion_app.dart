import 'package:flutter/material.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/farms/data/farm_repository.dart';
import '../features/home/presentation/app_shell.dart';
import 'app_theme.dart';

class AgroGestionApp extends StatefulWidget {
  const AgroGestionApp({
    required this.authRepository,
    required this.farmRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final FarmRepository farmRepository;

  @override
  State<AgroGestionApp> createState() => _AgroGestionAppState();
}

class _AgroGestionAppState extends State<AgroGestionApp> {
  AuthSession? _session;
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await widget.authRepository.restoreSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _isRestoring = false;
    });
  }

  void _onSignedIn(AuthSession session) {
    setState(() => _session = session);
  }

  Future<void> _onSignOut() async {
    await widget.authRepository.signOut();
    if (mounted) setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroGestion',
      debugShowCheckedModeBanner: false,
      theme: buildAgroGestionTheme(),
      home: _isRestoring
          ? const _LoadingScreen()
          : _session == null
          ? LoginScreen(
              authRepository: widget.authRepository,
              onSignedIn: _onSignedIn,
            )
          : AppShell(
              session: _session!,
              authRepository: widget.authRepository,
              farmRepository: widget.farmRepository,
              onSignOut: _onSignOut,
            ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
