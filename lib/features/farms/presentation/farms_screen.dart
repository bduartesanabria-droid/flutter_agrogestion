import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../data/farm_repository.dart';
import '../domain/farm.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({
    required this.session,
    required this.repository,
    super.key,
  });

  final AuthSession session;
  final FarmRepository repository;

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  late Future<List<Farm>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _farmsFuture = widget.repository.list(widget.session.token);

  bool get _canCreate =>
      widget.session.role == 'admin' || widget.session.role == 'agricultor';

  Future<void> _createFarm() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva finca'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 150,
          decoration: const InputDecoration(labelText: 'Nombre de la finca'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await widget.repository.create(widget.session.token, name);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Finca registrada.')));
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo registrar la finca. Intente de nuevo.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Mis fincas'),
            actions: _canCreate
                ? [
                    IconButton(
                      tooltip: 'Registrar finca',
                      onPressed: _createFarm,
                      icon: const Icon(Icons.add),
                    ),
                  ]
                : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Farm>>(
                future: _farmsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error! as ApiException).message
                        : 'No pudimos cargar sus fincas.';
                    return _ErrorState(
                      message: message,
                      onRetry: () => setState(_reload),
                    );
                  }
                  final farms = snapshot.data ?? const <Farm>[];
                  if (farms.isEmpty) return const _EmptyFarmsState();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Las fincas a las que tiene acceso.',
                        style: TextStyle(color: agroMuted),
                      ),
                      const SizedBox(height: 16),
                      for (final farm in farms) ...[
                        _FarmCard(farm: farm),
                        const SizedBox(height: 11),
                      ],
                      const SizedBox(height: 10),
                      if (_canCreate)
                        OutlinedButton.icon(
                          onPressed: _createFarm,
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar finca'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE7F2EB),
        child: Icon(Icons.landscape_outlined, color: agroGreen),
      ),
      title: Text(
        farm.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Finca asignada'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El detalle de finca se conectará al completar sus endpoints.',
          ),
        ),
      ),
    ),
  );
}

class _EmptyFarmsState extends StatelessWidget {
  const _EmptyFarmsState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 65),
    child: Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F2EB),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Icon(
            Icons.landscape_outlined,
            color: agroGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Registre su primera finca para empezar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aquí verá las fincas que tiene asignadas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: agroMuted),
        ),
        const SizedBox(height: 20),
        if (context.findAncestorStateOfType<_FarmsScreenState>()?._canCreate ??
            false)
          FilledButton.icon(
            onPressed: () => context
                .findAncestorStateOfType<_FarmsScreenState>()
                ?._createFarm(),
            icon: const Icon(Icons.add),
            label: const Text('Registrar finca'),
          ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 44, color: agroMuted),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Intentar de nuevo'),
        ),
      ],
    ),
  );
}
