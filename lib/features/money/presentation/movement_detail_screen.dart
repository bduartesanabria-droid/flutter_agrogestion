import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/layout.dart';
import '../data/money_repository.dart';

class MovementDetailScreen extends StatelessWidget {
  const MovementDetailScreen({required this.movement, super.key});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final m = movement;
    final color = m.cancelled
        ? AgroColors.outline
        : m.isIncome
        ? AgroColors.success
        : AgroColors.error;
    return DetailScaffold(
      title: m.isIncome ? 'Detalle de ingreso' : 'Detalle de gasto',
      subtitle: m.category,
      body: AgroPage(
        bottomClearance: AgroSpace.xl,
        children: [
          AgroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  m.cancelled
                      ? 'Anulado'
                      : m.isIncome
                      ? 'Ingreso confirmado'
                      : 'Gasto confirmado',
                  tone: m.cancelled ? Tone.neutral : Tone.ok,
                  icon: m.cancelled
                      ? Icons.block_rounded
                      : Icons.verified_outlined,
                ),
                const SizedBox(height: 12),
                AmountText(
                  formatCop(m.amount),
                  color: color,
                  style: AgroText.monoXl.copyWith(
                    fontSize: 32,
                    decoration: m.cancelled ? TextDecoration.lineThrough : null,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                Text('pesos colombianos (COP)', style: AgroText.bodySm),
              ],
            ),
          ),
          const SectionTitle('Trazabilidad'),
          AgroCard(
            child: Column(
              children: [
                InfoRow(
                  label: 'Tipo',
                  value: m.isIncome ? 'Ingreso' : 'Gasto',
                  icon: Icons.swap_vert_rounded,
                ),
                const Divider(),
                InfoRow(
                  label: 'Categoría',
                  value: m.category,
                  icon: Icons.category_outlined,
                ),
                const Divider(),
                InfoRow(
                  label: 'Finca',
                  value: app.activeFarm?.name ?? '—',
                  icon: Icons.landscape_outlined,
                ),
                const Divider(),
                InfoRow(
                  label: 'Código',
                  value: m.id.substring(0, 8).toUpperCase(),
                  mono: true,
                  icon: Icons.tag_rounded,
                ),
              ],
            ),
          ),
          const Gap(16),
          AgroCard(
            color: AgroColors.surfaceLow,
            elevated: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  size: 20,
                  color: AgroColors.primaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los movimientos no se eliminan: se anulan dejando constancia con el motivo y quién lo hizo.',
                    style: AgroText.bodySm.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          if (app.access.cancelsMoney && !m.cancelled) ...[
            const Gap(16),
            WideButton(
              label: 'Anular movimiento',
              icon: Icons.block_rounded,
              outlined: true,
              destructive: true,
              onPressed: () async {
                final ok = await showAgroSheet<bool>(
                  context,
                  builder: (_) => _CancelForm(app: app, movement: m),
                );
                if (ok == true && context.mounted) {
                  app.markChanged();
                  showSnack(context, 'Movimiento anulado.');
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelForm extends StatefulWidget {
  const _CancelForm({required this.app, required this.movement});

  final AppController app;
  final Movement movement;

  @override
  State<_CancelForm> createState() => _CancelFormState();
}

class _CancelFormState extends State<_CancelForm> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Anular movimiento',
    subtitle: 'Escriba el motivo; queda guardado en la bitácora.',
    submitLabel: 'Anular',
    onSubmit: () => widget.app.money.cancel(
      widget.app.activeFarm!.id,
      widget.movement,
      reason: _reason.text.trim(),
    ),
    children: [
      LabeledField(
        label: 'Motivo',
        controller: _reason,
        maxLines: 3,
        maxLength: 500,
        validator: (v) => requiredText(v, 'Escriba el motivo de la anulación.'),
      ),
    ],
  );
}
