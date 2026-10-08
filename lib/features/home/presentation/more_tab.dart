import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../account/presentation/account_screen.dart';
import '../../content/presentation/glossary_screen.dart';
import '../../content/presentation/knowledge_screen.dart';
import '../../content/presentation/news_screen.dart';
import '../../farms/presentation/farms_screen.dart';
import '../../production/presentation/crops_screen.dart';
import '../../risks/presentation/events_screen.dart';
import '../../workers/presentation/workers_screen.dart';
import 'farm_selector.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final access = app.access;

    ListRow row(String title, String subtitle, IconData icon, Widget screen) =>
        ListRow(
          onTap: () => pushScreen(context, screen),
          leading: IconBadge(icon: icon),
          title: title,
          subtitle: subtitle,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AgroColors.outline,
          ),
        );

    final field = <Widget>[
      row(
        'Mis fincas y lotes',
        'Fincas, lotes y área',
        Icons.map_outlined,
        const FarmsScreen(),
      ),
      if (access.seesWorkers)
        row(
          'Trabajadores',
          'Jornaleros, contratistas y fijos',
          Icons.groups_outlined,
          const WorkersScreen(),
        ),
      if (access.managesCatalog)
        row(
          'Catálogo de cultivos',
          'Perfiles que gobiernan el ciclo',
          Icons.eco_outlined,
          const CropsScreen(),
        ),
      if (access.seesRisks)
        row(
          'Eventos adversos',
          'Heladas, plagas y lluvias',
          Icons.warning_amber_rounded,
          const EventsScreen(),
        ),
    ];

    return AgroPage(
      children: [
        const FarmSelector(inPage: true),
        const Gap(16),
        AgroCard(
          onTap: () => pushScreen(context, const AccountScreen()),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AgroColors.secondaryContainer,
                child: Text(
                  app.session.name.isEmpty
                      ? '?'
                      : app.session.name[0].toUpperCase(),
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
                      app.session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.headlineMd,
                    ),
                    const SizedBox(height: 4),
                    StatusPill(access.roleLabel, tone: Tone.ok),
                    const SizedBox(height: 4),
                    Text(
                      app.session.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.monoSm,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AgroColors.outline,
              ),
            ],
          ),
        ),
        const SectionTitle('Operación de campo'),
        RowGroup(children: field),
        const SectionTitle('Conocimiento y ayuda'),
        RowGroup(
          children: [
            row(
              'Biblioteca de conocimiento',
              'Problemas y manejo validado',
              Icons.menu_book_outlined,
              const KnowledgeScreen(),
            ),
            row(
              'Glosario del campo',
              'Términos del agro explicados',
              Icons.school_outlined,
              const GlossaryScreen(),
            ),
            row(
              'Novedades de mi región',
              'Noticias y alertas vigentes',
              Icons.notifications_none_rounded,
              const NewsScreen(),
            ),
          ],
        ),
        const SectionTitle('Cuenta y privacidad'),
        RowGroup(
          children: [
            row(
              'Mi cuenta',
              'Datos, privacidad y autorización',
              Icons.shield_outlined,
              const AccountScreen(),
            ),
          ],
        ),
        const Gap(24),
        WideButton(
          label: 'Cerrar sesión',
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
            if (yes) await app.onSignOut();
          },
        ),
        const Gap(8),
        Text(
          'Su sesión dura 60 minutos y se guarda de forma segura en este dispositivo.',
          textAlign: TextAlign.center,
          style: AgroText.bodySm,
        ),
      ],
    );
  }
}
