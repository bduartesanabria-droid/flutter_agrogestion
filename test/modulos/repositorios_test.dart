import 'package:agrogestion/core/api/backend.dart';
import 'package:agrogestion/features/farms/data/farm_repository.dart';
import 'package:agrogestion/features/home/data/home_repository.dart';
import 'package:agrogestion/features/money/data/money_repository.dart';
import 'package:agrogestion/features/production/data/production_repository.dart';
import 'package:agrogestion/features/workers/data/workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';

Backend _backend(FakeBackend fake) => Backend(fake.client(), 'token-admin');

void main() {
  test('fincas y lotes se leen con sus áreas', () async {
    final repo = FarmRepository(_backend(FakeBackend()));
    final farms = await repo.list();
    expect(farms.single.name, 'Finca La Esperanza');
    expect(farms.single.areaHa, 18.5);
    final lots = await repo.lots(farmId);
    expect(lots.map((l) => l.areaHa), [4.5, 3.2]);
  });

  test('una siembra trae su ciclo abierto', () async {
    final repo = ProductionRepository(_backend(FakeBackend()));
    final overview = await repo.overview(plantingId);
    expect(overview.planting.openCycle?.type, 'levante');
    expect(overview.counts.single.alive, 17100);
    expect(overview.indicators.length, 2);
    expect(overview.schedule.first.done, isTrue);
    expect(overview.schedule[1].delayDays, 4);
  });

  test('el flujo de caja y los movimientos se combinan', () async {
    final repo = MoneyRepository(_backend(FakeBackend()));
    final overview = await repo.overview(farmId);
    expect(overview.flow.balance, 8400000);
    expect(overview.flow.margin, closeTo(56.57, 0.01));
    expect(overview.movements.length, 4);
    expect(overview.movements.where((m) => m.cancelled).length, 1);
    expect(overview.movements.firstWhere((m) => m.isIncome).amount, 14850000);
  });

  test('los trabajadores enmascaran el documento', () async {
    final repo = WorkersRepository(_backend(FakeBackend()));
    final workers = await repo.list(farmId);
    expect(workers.first.maskedDocument, 'CC ****5831');
    expect(workers.last.maskedDocument, 'Sin documento');
    expect(workers.first.initials, 'PN');
  });

  test('el inicio resume avisos y eventos', () async {
    final repo = HomeRepository(_backend(FakeBackend()));
    final overview = await repo.overview();
    expect(overview.activePlantings, 1);
    expect(overview.notices.single.risk, 'Helada');
    expect(overview.recentEvents.single.severity, 'moderada');
  });

  test('registrar una labor crea la actividad y luego el jornal', () async {
    final fake = FakeBackend();
    final repo = WorkersRepository(_backend(fake));
    await repo.registerWork(
      farmId,
      cycleId: cycleId,
      name: 'Socola',
      phase: 'preparacion',
      date: '2026-10-07',
      workedArea: 1,
      workers: 12,
      days: 3,
      dailyValue: 60000,
    );
    final posts = fake.calls.where((c) => c.startsWith('POST')).toList();
    expect(posts, [
      'POST fincas/$farmId/actividades',
      'POST fincas/$farmId/jornales',
    ]);
  });
}
