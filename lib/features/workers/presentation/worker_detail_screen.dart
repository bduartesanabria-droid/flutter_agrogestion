import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../data/workers_repository.dart';
import 'workers_screen.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({required this.worker, super.key});

  final Worker worker;

  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: worker.name,
    subtitle: 'Ficha laboral',
    body: AgroPage(
      bottomClearance: AgroSpace.xl,
      children: [
        AgroCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AgroColors.secondaryContainer,
                child: Text(
                  worker.initials,
                  style: AgroText.headlineMd.copyWith(
                    color: AgroColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.headlineMd,
                    ),
                    const SizedBox(height: 6),
                    StatusPill(
                      workerTypeLabel(worker.type),
                      tone: worker.status == 'activo' ? Tone.ok : Tone.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
        AgroCard(
          child: Column(
            children: [
              InfoRow(
                label: 'Documento',
                value: worker.maskedDocument,
                mono: true,
                icon: Icons.badge_outlined,
              ),
              const Divider(),
              InfoRow(
                label: 'Teléfono',
                value: worker.phone ?? 'Sin registrar',
                icon: Icons.call_outlined,
              ),
              const Divider(),
              InfoRow(
                label: 'Jornal habitual',
                value: formatCop(worker.dailyRate),
                mono: true,
                icon: Icons.payments_outlined,
              ),
              const Divider(),
              InfoRow(
                label: 'Estado',
                value: humanize(worker.status),
                icon: Icons.verified_user_outlined,
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
                Icons.policy_outlined,
                size: 20,
                color: AgroColors.primaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Información laboral protegida por la Ley 1581 de 2012. Su uso es exclusivo para liquidar jornales en la finca.',
                  style: AgroText.bodySm.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
