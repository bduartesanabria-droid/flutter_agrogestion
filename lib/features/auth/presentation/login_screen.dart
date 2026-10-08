import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authRepository,
    required this.onSignedIn,
    super.key,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) widget.onSignedIn(session);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'No se pudo conectar. Revise la dirección del servidor y su conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AgroSpace.md,
                AgroSpace.lg,
                AgroSpace.md,
                AgroSpace.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const IconBadge(
                          icon: Icons.eco_rounded,
                          size: 44,
                          background: AgroColors.secondaryContainer,
                          foreground: AgroColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AgroGestión',
                            style: AgroText.headlineMd.copyWith(
                              color: AgroColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AgroSpace.lg),
                    AgroCard(
                      padding: const EdgeInsets.all(AgroSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Iniciar sesión', style: AgroText.headlineLg),
                          const SizedBox(height: 6),
                          Text(
                            'Su finca, sus labores y sus cuentas en un solo lugar.',
                            style: AgroText.bodyMd.copyWith(
                              color: AgroColors.onSurfaceVariant,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AgroColors.errorContainer,
                                  borderRadius: BorderRadius.circular(
                                    AgroRadius.md,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 20,
                                      color: AgroColors.onErrorContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AgroText.bodyMd.copyWith(
                                          color: AgroColors.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text('Correo electrónico', style: AgroText.labelMd),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('login_email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'nombre@correo.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Escriba un correo válido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text('Contraseña', style: AgroText.labelMd),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('login_password'),
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Ingrese su contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Escriba su contraseña.'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const Key('login_submit'),
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¿Olvidó su clave? Pida al administrador que la restablezca.',
                            textAlign: TextAlign.center,
                            style: AgroText.bodySm,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AgroSpace.md),
                    AgroCard(
                      color: AgroColors.surfaceLow,
                      elevated: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: AgroColors.primaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Su sesión dura 60 minutos. Después se le pedirá ingresar de nuevo.',
                              style: AgroText.bodySm.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
