import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/account/presentation/consent_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/app_shell.dart';
import 'app_scope.dart';

class AgroGestionApp extends StatefulWidget {
  const AgroGestionApp({
    required this.api,
    required this.authRepository,
    super.key,
  });

  final ApiClient api;
  final AuthRepository authRepository;

  @override
  State<AgroGestionApp> createState() => _AgroGestionAppState();
}

enum _Consent { unknown, pending, accepted }

class _AgroGestionAppState extends State<AgroGestionApp> {
  AppController? _controller;
  _Consent _consent = _Consent.unknown;
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    widget.api.onUnauthorized = _onSignOut;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await widget.authRepository.restoreSession();
    if (!mounted) return;
    if (session != null) await _start(session);
    if (mounted) setState(() => _isRestoring = false);
  }

  Future<void> _start(AuthSession session) async {
    final controller = AppController(
      session: session,
      api: widget.api,
      onSignOut: _onSignOut,
    );
    await controller.loadFarms();
    var consent = _Consent.accepted;
    try {
      consent = await controller.account.consent() == null
          ? _Consent.pending
          : _Consent.accepted;
    } catch (_) {
      consent = _Consent.accepted;
    }
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _consent = consent;
    });
  }

  Future<void> _onSignIn(AuthSession session) async {
    await _start(session);
  }

  Future<void> _onSignOut() async {
    if (_controller == null) return;
    await widget.authRepository.signOut();
    if (mounted) {
      setState(() {
        _controller = null;
        _consent = _Consent.unknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return MaterialApp(
      title: 'AgroGestión',
      debugShowCheckedModeBanner: false,
      theme: buildAgroGestionTheme(),
      builder: (context, child) => controller == null
          ? child!
          : AppScope(controller: controller, child: child!),
      home: _isRestoring
          ? const _LoadingScreen()
          : controller == null
          ? LoginScreen(
              authRepository: widget.authRepository,
              onSignedIn: _onSignIn,
            )
          : _consent == _Consent.pending
          ? ConsentScreen(
              onAccepted: () => setState(() => _consent = _Consent.accepted),
            )
          : const AppShell(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
