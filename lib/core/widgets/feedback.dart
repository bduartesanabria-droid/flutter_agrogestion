import 'package:flutter/material.dart';

import '../theme/tokens.dart';

Future<T?> showAgroSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollable = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AgroSpace.md,
              0,
              AgroSpace.md,
              AgroSpace.md,
            ),
            child: builder(context),
          )
        : builder(context),
  ),
);

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: error
                  ? AgroColors.errorContainer
                  : AgroColors.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AgroColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AgroRadius.xl),
      ),
      title: Text(title, style: AgroText.headlineMd),
      content: Text(message, style: AgroText.bodyMd),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AgroColors.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class WideButton extends StatelessWidget {
  const WideButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.outlined = false,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool outlined;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    final enabled = busy ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              style: destructive
                  ? OutlinedButton.styleFrom(
                      foregroundColor: AgroColors.error,
                      side: const BorderSide(
                        color: AgroColors.error,
                        width: 1.5,
                      ),
                    )
                  : null,
              onPressed: enabled,
              child: child,
            )
          : FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: AgroColors.error)
                  : null,
              onPressed: enabled,
              child: child,
            ),
    );
  }
}
