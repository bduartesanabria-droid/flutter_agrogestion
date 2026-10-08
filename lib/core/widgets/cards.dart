import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AgroCard extends StatelessWidget {
  const AgroCard({
    required this.child,
    this.padding = const EdgeInsets.all(AgroSpace.md),
    this.accent,
    this.onTap,
    this.color = AgroColors.surfaceLowest,
    this.elevated = true,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;
  final Color color;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AgroRadius.lg);
    Widget body = Padding(padding: padding, child: child);
    if (accent != null) {
      body = Stack(
        children: [
          body,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 5, color: accent),
          ),
        ],
      );
    }
    return Semantics(
      label: semanticLabel,
      container: semanticLabel != null,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: AgroColors.border),
          boxShadow: elevated ? AgroShadows.level1 : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: onTap == null ? body : InkWell(onTap: onTap, child: body),
          ),
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    this.background = AgroColors.surfaceMid,
    this.foreground = AgroColors.primaryContainer,
    this.size = 40,
    this.circle = false,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(AgroRadius.md),
    ),
    child: Icon(icon, size: size * 0.5, color: foreground),
  );
}

class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.prefix,
    this.badgeBackground = AgroColors.secondaryContainer,
    this.badgeForeground = AgroColors.onSecondaryContainer,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final String? prefix;
  final IconData icon;
  final Color badgeBackground;
  final Color badgeForeground;

  @override
  Widget build(BuildContext context) => AgroCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.bodySm,
              ),
            ),
            const SizedBox(width: 8),
            IconBadge(
              icon: icon,
              size: 28,
              circle: true,
              background: badgeBackground,
              foreground: badgeForeground,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  if (prefix != null)
                    TextSpan(
                      text: '$prefix ',
                      style: AgroText.monoSm.copyWith(
                        color: AgroColors.outline,
                      ),
                    ),
                  TextSpan(text: value, style: AgroText.monoXl),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption ?? ' ',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AgroText.bodySm,
        ),
      ],
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final bool mono;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AgroColors.outline),
          const SizedBox(width: 10),
        ],
        Expanded(flex: 4, child: Text(label, style: AgroText.bodySm)),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: mono ? AgroText.monoMd : AgroText.labelMd,
          ),
        ),
      ],
    ),
  );
}

class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.meta,
    this.onTap,
    this.titleMaxLines = 1,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AgroText.labelMd,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.bodySm,
                    ),
                  ],
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AgroText.monoSm,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    ),
  );
}

class RowGroup extends StatelessWidget {
  const RowGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AgroCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
          children[i],
        ],
      ],
    ),
  );
}

class AmountText extends StatelessWidget {
  const AmountText(
    this.text, {
    this.color = AgroColors.onSurface,
    this.style = AgroText.monoMd,
    this.alignment = Alignment.centerRight,
    super.key,
  });

  final String text;
  final Color color;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: style.copyWith(color: color),
    ),
  );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({
    required this.value,
    this.color = AgroColors.primaryContainer,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AgroRadius.pill),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: height,
      color: color,
      backgroundColor: AgroColors.surfaceHigh,
    ),
  );
}
