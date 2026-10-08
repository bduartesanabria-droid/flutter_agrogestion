import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/layout.dart';
import '../data/risks_repository.dart';
import 'labels.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({required this.event, required this.risk, super.key});

  final AdverseEvent event;
  final RiskType? risk;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late AdverseEvent _event = widget.event;
  bool _busy = false;

  Future<void> _finish() async {
    final app = context.app;
    final yes = await confirmDialog(
      context,
      title: 'Marcar como terminado',
      message: 'El evento queda cerrado con fecha de hoy.',
      confirmLabel: 'Terminar evento',
    );
    if (!yes || !mounted) return;
    setState(() => _busy = true);
    try {
      await app.risks.close(_event.id, isoDate(DateTime.now()));
      final fresh = await app.risks.event(_event.id);
      if (!mounted) return;
      setState(() => _event = fresh);
      showSnack(context, 'Evento terminado.');
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'No hay conexión con el servidor.', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final event = _event;
    return DetailScaffold(
      title: widget.risk?.name ?? 'Evento adverso',
      subtitle: 'Desde el ${formatDate(event.start)}',
      body: AgroPage(
        bottomClearance: AgroSpace.xl,
        children: [
          EqualGrid(
            columns: 2,
            children: [
              KpiTile(
                label: 'Severidad',
                value: humanize(event.severity),
                icon: Icons.speed_rounded,
                caption: event.active ? 'evento en curso' : 'evento terminado',
                badgeBackground: toneBackground(severityTone(event.severity)),
                badgeForeground: toneForeground(severityTone(event.severity)),
              ),
              KpiTile(
                label: 'Pérdida estimada',
                value: event.estimatedLoss == null
                    ? '—'
                    : formatNumber(event.estimatedLoss!.round()),
                prefix: event.estimatedLoss == null ? null : '\$',
                icon: Icons.trending_down_rounded,
                caption: event.lossPercent == null
                    ? 'sin porcentaje'
                    : '${formatNumber(event.lossPercent, decimals: 0)}% de la producción',
                badgeBackground: AgroColors.errorContainer,
                badgeForeground: AgroColors.error,
              ),
            ],
          ),
          const SectionTitle('Detalle'),
          AgroCard(
            child: Column(
              children: [
                InfoRow(
                  label: 'Tipo de riesgo',
                  value: humanize(widget.risk?.type ?? '—'),
                  icon: Icons.category_outlined,
                ),
                const Divider(),
                InfoRow(
                  label: 'Inicio',
                  value: formatDate(event.start),
                  icon: Icons.event_outlined,
                ),
                const Divider(),
                InfoRow(
                  label: 'Fin',
                  value: event.end == null ? 'En curso' : formatDate(event.end),
                  icon: Icons.event_available_outlined,
                ),
                const Divider(),
                InfoRow(
                  label: 'Área afectada',
                  value: event.affectedArea == null
                      ? 'Sin dato'
                      : formatHa(event.affectedArea),
                  icon: Icons.crop_square_rounded,
                ),
              ],
            ),
          ),
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SectionTitle('Notas'),
            AgroCard(child: Text(event.notes!, style: AgroText.bodyMd)),
          ],
          if (event.active && app.access.registersFieldWork) ...[
            const Gap(24),
            WideButton(
              label: 'Marcar como terminado',
              icon: Icons.check_circle_outline,
              busy: _busy,
              onPressed: _finish,
            ),
          ],
        ],
      ),
    );
  }
}
