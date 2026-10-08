import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../farms/domain/farm.dart';

class FarmSelector extends StatelessWidget {
  const FarmSelector({this.compact = false, this.inPage = false, super.key});

  final bool compact;

  final bool inPage;

  @override
  Widget build(BuildContext context) {
    if (inPage && isWide(context)) return const SizedBox.shrink();
    final app = context.app;
    final farm = app.activeFarm;
    final String title;
    final String caption;
    if (app.farmsLoading) {
      title = 'Cargando fincas';
      caption = 'Finca activa';
    } else if (app.farmsError != null) {
      title = 'No se pudieron cargar las fincas';
      caption = 'Toque para reintentar';
    } else if (farm == null) {
      title = 'Sin fincas registradas';
      caption = 'Finca activa';
    } else {
      title = farm.name;
      caption = 'Finca activa';
    }
    final canPick = app.farms.length > 1;

    return Semantics(
      button: true,
      label: '$caption: $title',
      child: Material(
        color: AgroColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AgroRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AgroRadius.md),
          onTap: app.farmsError != null
              ? app.loadFarms
              : canPick
              ? () => _pick(context)
              : null,
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 48 : 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AgroRadius.md),
              border: Border.all(color: AgroColors.border),
            ),
            child: Row(
              children: [
                const IconBadge(icon: Icons.location_on_outlined, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AgroText.bodySm.copyWith(fontSize: 11),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AgroText.labelMd,
                      ),
                    ],
                  ),
                ),
                if (canPick)
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AgroColors.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final app = context.app;
    final chosen = await showAgroSheet<Farm>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Elegir finca', style: AgroText.headlineMd),
          const SizedBox(height: 12),
          for (final farm in app.farms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 12,
              leading: const IconBadge(icon: Icons.landscape_outlined),
              title: Text(
                farm.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AgroText.labelMd,
              ),
              subtitle: farm.areaHa == null
                  ? null
                  : Text(formatHa(farm.areaHa), style: AgroText.bodySm),
              trailing: farm.id == app.activeFarm?.id
                  ? const Icon(
                      Icons.check_circle,
                      color: AgroColors.primaryContainer,
                    )
                  : null,
              onTap: () => Navigator.pop(context, farm),
            ),
        ],
      ),
    );
    if (chosen != null) app.selectFarm(chosen);
  }
}
