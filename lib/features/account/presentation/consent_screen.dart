import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/account_repository.dart';
import 'account_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({required this.onAccepted, super.key});

  final VoidCallback onAccepted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _ai = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit(Policy policy) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.app.account.accept(
        version: policy.version,
        aiTransfer: _ai,
      );
      if (mounted) widget.onAccepted();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No hay conexión con el servidor.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<Policy>(
      load: app.account.policy,
      skeleton: const DetailScaffold(
        title: 'Sus datos',
        body: AgroPage(children: [SkeletonList(rowHeight: 140)]),
      ),
      builder: (context, policy, reload) => Scaffold(
        appBar: AppBar(
          title: Text('Sus datos', style: AgroText.headlineMd),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(onPressed: app.onSignOut, child: const Text('Salir')),
          ],
        ),
        body: SafeArea(
          child: AgroPage(
            bottomClearance: AgroSpace.xl,
            children: [
              Text(
                'Para operar y proteger su información agronómica necesitamos su autorización expresa (Ley 1581 de 2012, Habeas Data).',
                style: AgroText.bodyMd.copyWith(height: 1.5),
              ),
              const SectionTitle('Datos que se tratan'),
              RowGroup(
                children: [
                  for (final item in policy.dataUsed)
                    ListRow(
                      leading: const IconBadge(
                        icon: Icons.verified_user_outlined,
                      ),
                      title: item,
                      titleMaxLines: 3,
                    ),
                ],
              ),
              const Gap(16),
              AgroCard(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Acepto el tratamiento de mis datos personales según la política de privacidad.',
                        style: AgroText.bodyMd,
                      ),
                      subtitle: Text('REQUERIDO', style: AgroText.labelSm),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      value: _ai,
                      onChanged: (v) => setState(() => _ai = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Autorizo enviar fotos de cultivos al asistente de inteligencia artificial.',
                        style: AgroText.bodyMd,
                      ),
                      subtitle: Text('OPCIONAL', style: AgroText.labelSm),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Text(
                'Puede retirar la autorización de fotos en cualquier momento.',
                style: AgroText.bodySm,
              ),
              if (_error != null) ...[
                const Gap(12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: AgroText.bodyMd.copyWith(color: AgroColors.error),
                  ),
                ),
              ],
              const Gap(16),
              WideButton(
                label: 'Aceptar y continuar',
                icon: Icons.arrow_forward_rounded,
                busy: _busy,
                onPressed: _accepted ? () => _submit(policy) : null,
              ),
              const Gap(12),
              WideButton(
                label: 'Ver política completa',
                icon: Icons.menu_book_outlined,
                outlined: true,
                onPressed: () => showPolicySheet(context, policy),
              ),
              const Gap(16),
              Text(
                'Versión de la política ${policy.version}',
                textAlign: TextAlign.center,
                style: AgroText.monoSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
