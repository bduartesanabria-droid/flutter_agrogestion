import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'layout.dart';

enum Tone { ok, warn, danger, info, neutral }

class ToneColors {
  const ToneColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

ToneColors toneColors(Tone tone) => switch (tone) {
  Tone.ok => const ToneColors(
    AgroColors.secondaryContainer,
    AgroColors.primary,
  ),
  Tone.warn => const ToneColors(AgroColors.tertiaryFixed, AgroColors.tertiary),
  Tone.danger => const ToneColors(
    AgroColors.errorContainer,
    AgroColors.onErrorContainer,
  ),
  Tone.info => const ToneColors(AgroColors.infoContainer, AgroColors.info),
  Tone.neutral => const ToneColors(
    AgroColors.surfaceHigh,
    AgroColors.onSurfaceVariant,
  ),
};

Color toneForeground(Tone tone) => toneColors(tone).foreground;
Color toneBackground(Tone tone) => toneColors(tone).background;

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {this.tone = Tone.neutral, this.icon, super.key});

  final String text;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(tone);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: boundedShare(context, 0.5)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AgroRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: colors.foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AgroText.labelSm.copyWith(color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.counts,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<int?>? counts;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: labels.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final active = i == selected;
        final count = counts != null && i < counts!.length ? counts![i] : null;
        return Semantics(
          button: true,
          selected: active,
          label: labels[i],
          child: Material(
            color: active
                ? AgroColors.primaryContainer
                : AgroColors.surfaceLowest,
            shape: StadiumBorder(
              side: BorderSide(
                color: active ? Colors.transparent : AgroColors.border,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (active) ...[
                      const Icon(Icons.check, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labels[i],
                      style: AgroText.labelMd.copyWith(
                        color: active ? Colors.white : AgroColors.outline,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AgroColors.primary
                              : AgroColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(AgroRadius.pill),
                        ),
                        child: Text(
                          '$count',
                          style: AgroText.monoSm.copyWith(
                            color: active
                                ? Colors.white
                                : AgroColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.icons,
    super.key,
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AgroColors.surfaceMid,
      borderRadius: BorderRadius.circular(AgroRadius.lg),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              label: labels[i],
              child: Material(
                color: i == selected
                    ? AgroColors.surfaceLowest
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AgroRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AgroRadius.md),
                  onTap: () => onSelected(i),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icons != null) ...[
                            Icon(
                              icons![i],
                              size: 18,
                              color: i == selected
                                  ? AgroColors.primaryContainer
                                  : AgroColors.outline,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AgroText.labelMd.copyWith(
                                color: i == selected
                                    ? AgroColors.primaryContainer
                                    : AgroColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
