import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../money/presentation/money_forms.dart';
import '../../risks/presentation/event_form.dart';
import 'work_forms.dart';

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    required this.tone,
    required this.run,
  });

  final String title;
  final String description;
  final String tag;
  final IconData icon;
  final Tone tone;
  final Future<bool> Function(BuildContext context) run;
}

Future<void> showQuickRegister(BuildContext context) async {
  final access = context.app.access;
  final actions = <_QuickAction>[
    if (access.registersFieldWork)
      _QuickAction(
        title: 'Labor con jornales',
        description:
            'Cuadrilla o trabajador, siembra, fase y jornales del día.',
        tag: 'Jornal',
        icon: Icons.groups_outlined,
        tone: Tone.ok,
        run: (c) => showWorkForm(c),
      ),
    if (access.registersMoney)
      _QuickAction(
        title: 'Gasto',
        description: 'Compra de insumos, fletes, mantenimiento o combustible.',
        tag: 'Egreso',
        icon: Icons.receipt_long_outlined,
        tone: Tone.danger,
        run: (c) => showExpenseForm(c),
      ),
    if (access.registersMoney)
      _QuickAction(
        title: 'Ingreso',
        description: 'Venta de cosecha o subproductos, con cantidad y precio.',
        tag: 'Venta',
        icon: Icons.payments_outlined,
        tone: Tone.ok,
        run: (c) => showIncomeForm(c),
      ),
    if (access.registersFieldWork)
      _QuickAction(
        title: 'Cosecha',
        description:
            'Cantidad recolectada por siembra, en kilos, arrobas o cargas.',
        tag: 'Pesaje',
        icon: Icons.inventory_2_outlined,
        tone: Tone.ok,
        run: (c) => showHarvestForm(c),
      ),
    if (access.registersFieldWork && access.seesRisks)
      _QuickAction(
        title: 'Evento adverso',
        description: 'Helada, plaga, sequía o daño, con severidad y pérdida.',
        tag: 'Riesgo',
        icon: Icons.warning_amber_rounded,
        tone: Tone.warn,
        run: (c) => showEventForm(c),
      ),
  ];

  final chosen = await showAgroSheet<_QuickAction>(
    context,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Registro rápido', style: AgroText.headlineMd),
        const SizedBox(height: 4),
        Text(
          sheetContext.app.activeFarm?.name ?? 'Sin finca activa',
          style: AgroText.bodySm,
        ),
        const SizedBox(height: 16),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActionTile(
              action: action,
              onTap: () => Navigator.pop(sheetContext, action),
            ),
          ),
      ],
    ),
  );
  if (chosen != null && context.mounted) await chosen.run(context);
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AgroCard(
    onTap: onTap,
    elevated: false,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          IconBadge(
            icon: action.icon,
            size: 48,
            background: toneBackground(action.tone),
            foreground: toneForeground(action.tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AgroText.labelMd.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(action.tag, tone: action.tone),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AgroColors.outline),
        ],
      ),
    ),
  );
}
