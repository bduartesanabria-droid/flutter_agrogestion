import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/content_repository.dart';

Tone _stateTone(String state) => switch (state) {
  'validado' => Tone.ok,
  'borrador' => Tone.warn,
  _ => Tone.neutral,
};

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return DetailScaffold(
      title: 'Biblioteca de conocimiento',
      subtitle: 'Plagas, enfermedades y manejo',
      body: AsyncBody<List<KnowledgeItem>>(
        load: app.content.knowledge,
        builder: (context, items, reload) {
          final shown = items
              .where(
                (i) =>
                    _query.isEmpty ||
                    i.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
          return AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar un problema',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const Gap(16),
              if (shown.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Sin fichas por ahora',
                    message:
                        'Las fichas validadas por expertos aparecerán aquí.',
                  ),
                )
              else
                RowGroup(
                  children: [
                    for (final item in shown)
                      ListRow(
                        onTap: () => pushScreen(
                          context,
                          KnowledgeDetailScreen(item: item),
                        ),
                        leading: const IconBadge(
                          icon: Icons.bug_report_outlined,
                        ),
                        title: item.name,
                        subtitle: humanize(item.type),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(
                              humanize(item.state),
                              tone: _stateTone(item.state),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AgroColors.outline,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class KnowledgeDetailScreen extends StatelessWidget {
  const KnowledgeDetailScreen({required this.item, super.key});

  final KnowledgeItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AsyncBody<KnowledgeDetail>(
      load: () => app.content.knowledgeDetail(item.id),
      skeleton: DetailScaffold(
        title: item.name,
        body: const AgroPage(children: [SkeletonList(rowHeight: 120)]),
      ),
      builder: (context, detail, reload) => DetailScaffold(
        title: item.name,
        subtitle: humanize(item.type),
        body: AgroPage(
          onRefresh: reload,
          bottomClearance: AgroSpace.xl,
          children: [
            AgroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    humanize(item.state),
                    tone: _stateTone(item.state),
                  ),
                  const SizedBox(height: 12),
                  Text('Causa', style: AgroText.labelMd),
                  const SizedBox(height: 4),
                  Text(
                    detail.cause.isEmpty
                        ? 'Sin causa registrada.'
                        : detail.cause,
                    style: AgroText.bodyMd.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SectionTitle('Síntomas'),
            _bullets(detail.symptoms, 'Sin síntomas registrados.'),
            const SectionTitle('Qué hacer'),
            _bullets(detail.handling, 'Aún no hay manejos validados.'),
            if (detail.notice != null) ...[
              const Gap(16),
              AgroCard(
                color: AgroColors.tertiaryFixed.withValues(alpha: 0.4),
                elevated: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AgroColors.tertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detail.notice!,
                        style: AgroText.bodySm.copyWith(
                          color: AgroColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bullets(List<String> items, String empty) => AgroCard(
    child: items.isEmpty
        ? Text(empty, style: AgroText.bodySm)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final text in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                        child: Text(
                          text,
                          style: AgroText.bodyMd.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}
