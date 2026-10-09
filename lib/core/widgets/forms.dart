import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../theme/tokens.dart';
import 'feedback.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefixText,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AgroText.labelMd),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: AgroText.monoMd.copyWith(color: AgroColors.outline),
            counterText: '',
          ),
        ),
      ],
    ),
  );
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    super.key,
  });

  final String label;
  final Map<T, String> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AgroText.labelMd),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          items: [
            for (final entry in items.entries)
              DropdownMenuItem<T>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

String? requiredText(
  String? value, [
  String message = 'Este campo es obligatorio.',
]) => value == null || value.trim().isEmpty ? message : null;

String? positiveNumber(String? value) {
  final number = num.tryParse((value ?? '').trim().replaceAll(',', '.'));
  if (number == null || number <= 0) return 'Escriba un valor mayor a cero.';
  return null;
}

final moneyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];

class FormSheet extends StatefulWidget {
  const FormSheet({
    required this.title,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  @override
  State<FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<FormSheet> {
  final _key = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Sin conexión. Este registro necesita internet; intente con señal.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: AgroText.headlineMd),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(widget.subtitle!, style: AgroText.bodySm),
        ],
        const SizedBox(height: 16),
        ...widget.children,
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AgroColors.errorContainer,
                borderRadius: BorderRadius.circular(AgroRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 20,
                    color: AgroColors.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AgroText.bodyMd.copyWith(
                        color: AgroColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        WideButton(label: widget.submitLabel, busy: _busy, onPressed: _submit),
      ],
    ),
  );
}

class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AgroText.labelMd),
        const SizedBox(height: 8),
        Material(
          color: AgroColors.surfaceLowest,
          borderRadius: BorderRadius.circular(AgroRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AgroRadius.lg),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AgroRadius.lg),
                border: Border.all(color: AgroColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(isoDate(value), style: AgroText.monoMd)),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AgroColors.outline,
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

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

double parseNumber(String text) =>
    double.parse(text.trim().replaceAll(',', '.'));

class InfoTotal extends StatelessWidget {
  const InfoTotal({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AgroColors.surfaceLow,
      borderRadius: BorderRadius.circular(AgroRadius.lg),
      border: Border.all(color: AgroColors.outlineVariant),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AgroText.labelMd)),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AgroText.monoMd),
          ),
        ),
      ],
    ),
  );
}
