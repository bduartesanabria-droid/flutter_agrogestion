import 'package:flutter/material.dart';

import '../theme/tokens.dart';

const double kContentMaxWidth = 880;

Future<T?> pushScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => screen));

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

class AgroPage extends StatelessWidget {
  const AgroPage({
    required this.children,
    this.onRefresh,
    this.padding,
    this.bottomClearance = AgroSpace.fabClearance,
    super.key,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: Padding(
              padding:
                  padding ??
                  EdgeInsets.fromLTRB(
                    AgroSpace.md,
                    AgroSpace.md,
                    AgroSpace.md,
                    bottomClearance,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class EqualGrid extends StatelessWidget {
  const EqualGrid({
    required this.children,
    this.columns,
    this.gap = 12,
    super.key,
  });

  final List<Widget> children;
  final int? columns;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cols = columns ?? (constraints.maxWidth >= 640 ? 4 : 2);
      final rows = <Widget>[];
      for (var start = 0; start < children.length; start += cols) {
        final slice = children.skip(start).take(cols).toList();
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cols; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: i < slice.length ? slice[i] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        );
        if (start + cols < children.length) rows.add(SizedBox(height: gap));
      }
      return Column(children: rows);
    },
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, this.caption, super.key});

  final String text;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AgroText.labelMd.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.9,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgroText.bodySm,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class TextLinkButton extends StatelessWidget {
  const TextLinkButton(this.label, this.onPressed, {this.icon, super.key});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (icon != null) ...[const SizedBox(width: 4), Icon(icon, size: 16)],
      ],
    ),
  );
}

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floating,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floating;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 64,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AgroText.headlineMd,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AgroText.bodySm,
            ),
        ],
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    ),
    body: SafeArea(top: false, child: body),
    floatingActionButton: floating,
    bottomNavigationBar: bottom,
  );
}
