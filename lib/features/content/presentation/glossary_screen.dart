import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/states.dart';
import '../data/content_repository.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return DetailScaffold(
      title: 'Glosario del campo',
      subtitle: 'Palabras del agro explicadas',
      body: AsyncBody<List<GlossaryTerm>>(
        load: app.content.glossary,
        builder: (context, terms, reload) {
          final shown = terms
              .where(
                (t) =>
                    _query.isEmpty ||
                    t.term.toLowerCase().contains(_query.toLowerCase()) ||
                    t.explanation.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
          return AgroPage(
            onRefresh: reload,
            bottomClearance: AgroSpace.xl,
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar un término',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const Gap(16),
              if (shown.isEmpty)
                const AgroCard(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No encontramos ese término',
                    message: 'Pruebe con otra palabra.',
                  ),
                )
              else
                for (final term in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AgroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  term.term,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AgroText.headlineMd,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                humanize(term.category),
                                tone: Tone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            term.explanation,
                            style: AgroText.bodyMd.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
