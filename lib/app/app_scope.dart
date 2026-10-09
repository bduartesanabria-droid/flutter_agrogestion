import 'package:flutter/material.dart';

import '../core/access/access.dart';
import '../core/api/api_client.dart';
import '../core/api/backend.dart';
import '../core/api/offline_cache.dart';
import '../core/api/offline_queue.dart';
import '../features/account/data/account_repository.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/content/data/content_repository.dart';
import '../features/farms/data/farm_repository.dart';
import '../features/farms/domain/farm.dart';
import '../features/home/data/home_repository.dart';
import '../features/inventory/data/inventory_repository.dart';
import '../features/money/data/money_repository.dart';
import '../features/payments/data/payments_repository.dart';
import '../features/processes/data/processes_repository.dart';
import '../features/production/data/production_repository.dart';
import '../features/production/domain/production.dart';
import '../features/risks/data/risks_repository.dart';
import '../features/workers/data/workers_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.session,
    required ApiClient api,
    required this.onSignOut,
  }) : access = Access(session),
       backend = Backend(
         api,
         session.token,
         cache: OfflineCache(session.userId),
         queue: OfflineQueue(session.userId),
       ) {
    farmsRepo = FarmRepository(backend);
    production = ProductionRepository(backend);
    money = MoneyRepository(backend);
    workers = WorkersRepository(backend);
    risks = RisksRepository(backend);
    home = HomeRepository(backend);
    content = ContentRepository(backend);
    account = AccountRepository(backend);
    payments = PaymentsRepository(backend);
    inventory = InventoryRepository(backend);
    processes = ProcessesRepository(backend);
  }

  final AuthSession session;
  final Access access;
  final Backend backend;
  final Future<void> Function() onSignOut;

  late final FarmRepository farmsRepo;
  late final ProductionRepository production;
  late final MoneyRepository money;
  late final WorkersRepository workers;
  late final RisksRepository risks;
  late final HomeRepository home;
  late final ContentRepository content;
  late final AccountRepository account;
  late final PaymentsRepository payments;
  late final InventoryRepository inventory;
  late final ProcessesRepository processes;

  List<Farm> farms = const [];
  Farm? activeFarm;
  bool farmsLoading = true;
  String? farmsError;
  Map<String, Crop> _crops = const {};
  bool _cropsLoaded = false;
  int revision = 0;

  Future<void> loadFarms() async {
    farmsLoading = true;
    farmsError = null;
    notifyListeners();
    try {
      farms = await farmsRepo.list();
      final keep = farms.where((f) => f.id == activeFarm?.id);
      activeFarm = keep.isNotEmpty
          ? keep.first
          : (farms.isEmpty ? null : farms.first);
    } on ApiException catch (error) {
      farmsError = error.message;
    } catch (_) {
      farmsError = 'No hay conexión con el servidor.';
    } finally {
      farmsLoading = false;
      notifyListeners();
    }
  }

  void selectFarm(Farm farm) {
    activeFarm = farm;
    revision++;
    notifyListeners();
  }

  void markChanged() {
    revision++;
    notifyListeners();
  }

  Future<Map<String, Crop>> crops() async {
    if (_cropsLoaded) return _crops;
    try {
      final list = await production.crops();
      _crops = {for (final c in list) c.id: c};
    } catch (_) {
      _crops = const {};
    }
    _cropsLoaded = true;
    return _crops;
  }

  String cropName(String id) => _crops[id]?.name ?? 'Cultivo';
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  AppController get app => AppScope.of(this);
}
