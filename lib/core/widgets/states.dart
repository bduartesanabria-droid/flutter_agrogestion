import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/tokens.dart';
import 'cards.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({this.height = 16, this.width, this.radius = 8, super.key});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Color.lerp(
          AgroColors.surfaceMid,
          AgroColors.surfaceHigh,
          _controller.value,
        ),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 3, this.rowHeight = 88, super.key});

  final int count;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AgroCard(
              child: SizedBox(
                height: rowHeight - 32,
                child: const Row(
                  children: [
                    Skeleton(height: 40, width: 40, radius: 12),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(height: 14),
                          SizedBox(height: 8),
                          Skeleton(height: 12, width: 140),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(
          icon: icon,
          size: 64,
          circle: true,
          background: AgroColors.surfaceMid,
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: AgroText.headlineMd),
        if (message != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: AgroText.bodyMd.copyWith(
                color: AgroColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'No pudimos cargar esto',
      message: message,
      actionLabel: onRetry == null ? null : 'Reintentar',
      onAction: onRetry,
    ),
  );
}

String errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'No hay conexión con el servidor. Revise su señal e intente de nuevo.';
}

typedef AsyncLoader<T> = Future<T> Function();

class AsyncBody<T> extends StatefulWidget {
  const AsyncBody({
    required this.load,
    required this.builder,
    this.skeleton,
    this.isEmpty,
    this.empty,
    super.key,
  });

  final AsyncLoader<T> load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;
  final Widget? skeleton;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  @override
  State<AsyncBody<T>> createState() => AsyncBodyState<T>();
}

class AsyncBodyState<T> extends State<AsyncBody<T>> {
  late Future<T> _future = widget.load();

  Future<void> reload() async {
    final next = widget.load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.skeleton ?? const SkeletonList();
      }
      if (snapshot.hasError) {
        return ErrorState(
          message: errorMessage(snapshot.error!),
          onRetry: reload,
        );
      }
      final data = snapshot.requireData;
      if (widget.isEmpty != null &&
          widget.isEmpty!(data) &&
          widget.empty != null) {
        return widget.empty!;
      }
      return widget.builder(context, data, reload);
    },
  );
}
