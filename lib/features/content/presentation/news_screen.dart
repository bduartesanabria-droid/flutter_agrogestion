import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/content_repository.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return DetailScaffold(
      title: 'Novedades de mi región',
      subtitle: 'Noticias y alertas vigentes',
      body: AsyncBody<List<NewsItem>>(
        load: app.content.news,
        builder: (context, items, reload) => AgroPage(
          onRefresh: reload,
          bottomClearance: AgroSpace.xl,
          children: [
            if (items.isEmpty)
              const AgroCard(
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No hay novedades vigentes',
                  message: 'Las noticias del sector aparecen aquí mientras estén vigentes.',
                ),
              )
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NewsCard(item: item),
                ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final days = item.daysLeft;
    final urgent = days <= 1;
    return AgroCard(
      accent: urgent ? AgroColors.tertiary : AgroColors.primaryContainer,
      padding: const EdgeInsets.fromLTRB(21, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.source.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.labelSm,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                days <= 0 ? 'Vence hoy' : 'Vence en $days días',
                tone: urgent ? Tone.warn : Tone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: AgroText.headlineMd.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(item.summary, style: AgroText.bodyMd.copyWith(height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Publicada el ${formatDate(item.published)}',
                  style: AgroText.monoSm,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: item.link));
                  if (context.mounted) {
                    showSnack(context, 'Enlace copiado.');
                  }
                },
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Copiar enlace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
