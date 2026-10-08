import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/forms.dart';

const expenseCategories = [
  'Mano de obra',
  'Insumos y fertilizantes',
  'Combustible y fletes',
  'Mantenimiento de herramientas',
  'Servicios y arriendos',
  'Otros gastos',
];

const incomeCategories = [
  'Venta de cosecha',
  'Venta de subproductos',
  'Venta de animales',
  'Otros ingresos',
];

Future<bool> showExpenseForm(BuildContext context) =>
    _show(context, (app) => _ExpenseForm(app: app));

Future<bool> showIncomeForm(BuildContext context) =>
    _show(context, (app) => _IncomeForm(app: app));

Future<bool> _show(
  BuildContext context,
  Widget Function(AppController app) builder,
) async {
  final app = context.app;
  if (app.activeFarm == null) {
    showSnack(context, 'Primero registre una finca.', error: true);
    return false;
  }
  final result = await showAgroSheet<bool>(
    context,
    builder: (_) => builder(app),
  );
  if (result == true) app.markChanged();
  return result == true;
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({required this.app});

  final AppController app;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _amount = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Registrar gasto',
    subtitle: widget.app.activeFarm?.name,
    submitLabel: 'Guardar gasto',
    onSubmit: () => widget.app.money.createExpense(
      widget.app.activeFarm!.id,
      category: _category!,
      amount: parseNumber(_amount.text),
      date: isoDate(_date),
    ),
    children: [
      LabeledDropdown<String>(
        label: 'Categoría',
        value: _category,
        items: {for (final c in expenseCategories) c: c},
        validator: (v) => v == null ? 'Elija una categoría.' : null,
        onChanged: (v) => setState(() => _category = v),
      ),
      LabeledField(
        label: 'Valor del gasto',
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixText: 'COP \$ ',
        inputFormatters: moneyFormatters,
        validator: positiveNumber,
      ),
      DateField(
        label: 'Fecha',
        value: _date,
        lastDate: DateTime.now(),
        onChanged: (d) => setState(() => _date = d),
      ),
    ],
  );
}

class _IncomeForm extends StatefulWidget {
  const _IncomeForm({required this.app});

  final AppController app;

  @override
  State<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<_IncomeForm> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _buyer = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();
  double _total = 0;

  void _recalc() {
    final q = double.tryParse(_quantity.text.trim().replaceAll(',', '.'));
    final p = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    setState(() => _total = (q ?? 0) * (p ?? 0));
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _buyer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Registrar ingreso',
    subtitle: widget.app.activeFarm?.name,
    submitLabel: 'Guardar ingreso',
    onSubmit: () => widget.app.money.createIncome(
      widget.app.activeFarm!.id,
      category: _category!,
      quantity: parseNumber(_quantity.text),
      unitPrice: parseNumber(_price.text),
      date: isoDate(_date),
      buyer: _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
    ),
    children: [
      LabeledDropdown<String>(
        label: 'Categoría',
        value: _category,
        items: {for (final c in incomeCategories) c: c},
        validator: (v) => v == null ? 'Elija una categoría.' : null,
        onChanged: (v) => setState(() => _category = v),
      ),
      LabeledField(
        label: 'Cantidad vendida',
        controller: _quantity,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: positiveNumber,
        inputFormatters: moneyFormatters,
        onChanged: (_) => _recalc(),
      ),
      LabeledField(
        label: 'Precio por unidad',
        controller: _price,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixText: 'COP \$ ',
        inputFormatters: moneyFormatters,
        validator: positiveNumber,
        onChanged: (_) => _recalc(),
      ),
      InfoTotal(label: 'Total del ingreso', value: formatCop(_total)),
      LabeledField(
        label: 'Comprador (opcional)',
        controller: _buyer,
        maxLength: 120,
        textCapitalization: TextCapitalization.words,
      ),
      DateField(
        label: 'Fecha',
        value: _date,
        lastDate: DateTime.now(),
        onChanged: (d) => setState(() => _date = d),
      ),
    ],
  );
}
