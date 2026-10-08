import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/account_repository.dart';

class _AccountData {
  const _AccountData(this.consent, this.policy);

  final Consent? consent;
  final Policy policy;
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final session = app.session;
    return DetailScaffold(
      title: 'Mi cuenta',
      subtitle: 'Datos y privacidad',
      body: AgroPage(
        bottomClearance: AgroSpace.xl,
        children: [
          AgroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AgroColors.secondaryContainer,
                      child: Text(
                        session.name.isEmpty
                            ? '?'
                            : session.name[0].toUpperCase(),
                        style: AgroText.headlineMd.copyWith(
                          color: AgroColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AgroText.headlineMd,
                          ),
                          const SizedBox(height: 6),
                          StatusPill(app.access.roleLabel, tone: Tone.ok),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                InfoRow(
                  label: 'Correo',
                  value: session.email,
                  icon: Icons.mail_outline_rounded,
                ),
                const Divider(),
                InfoRow(
                  label: 'Fincas asignadas',
                  value: formatNumber(session.farmIds.length),
                  icon: Icons.landscape_outlined,
                ),
              ],
            ),
          ),
          const SectionTitle(
            'Privacidad y Habeas Data',
            caption: 'Ley 1581 de 2012',
          ),
          AsyncBody<_AccountData>(
            load: () async => _AccountData(
              await app.account.consent(),
              await app.account.policy(),
            ),
            skeleton: const SkeletonList(count: 1, rowHeight: 140),
            builder: (context, data, reload) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AgroCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Tratamiento de datos',
                        value: data.consent == null
                            ? 'Pendiente'
                            : 'Autorizado',
                        icon: Icons.verified_user_outlined,
                      ),
                      const Divider(),
                      InfoRow(
                        label: 'Fotos al asistente',
                        value: data.consent?.aiTransfer == true
                            ? 'Autorizado'
                            : 'No autorizado',
                        icon: Icons.photo_camera_outlined,
                      ),
                      const Divider(),
                      InfoRow(
                        label: 'Política aceptada',
                        value: data.consent == null
                            ? '—'
                            : data.consent!.version,
                        mono: true,
                        icon: Icons.description_outlined,
                      ),
                      if (data.consent != null) ...[
                        const Divider(),
                        InfoRow(
                          label: 'Fecha',
                          value: formatDate(data.consent!.acceptedAt),
                          icon: Icons.event_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(12),
                WideButton(
                  label: 'Ver política completa',
                  icon: Icons.menu_book_outlined,
                  outlined: true,
                  onPressed: () => showPolicySheet(context, data.policy),
                ),
              ],
            ),
          ),
          const Gap(24),
          WideButton(
            label: 'Cerrar sesión en este dispositivo',
            icon: Icons.logout_rounded,
            outlined: true,
            destructive: true,
            onPressed: () async {
              final yes = await confirmDialog(
                context,
                title: 'Cerrar sesión',
                message: 'Tendrá que volver a ingresar su correo y contraseña.',
                confirmLabel: 'Cerrar sesión',
              );
              if (!yes) return;
              await app.onSignOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showPolicySheet(BuildContext context, Policy policy) =>
    showAgroSheet<void>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Política de datos', style: AgroText.headlineMd),
          Text('Versión ${policy.version}', style: AgroText.monoSm),
          _block('Datos que usamos', policy.dataUsed),
          _block('Para qué los usamos', policy.purposes),
          _block('Sus derechos', policy.rights),
        ],
      ),
    );

Widget _block(String title, List<String> items) => Padding(
  padding: const EdgeInsets.only(top: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AgroText.labelMd),
      const SizedBox(height: 6),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, right: 10),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: AgroColors.primaryContainer,
                ),
              ),
              Expanded(
                child: Text(item, style: AgroText.bodyMd.copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
    ],
  ),
);
