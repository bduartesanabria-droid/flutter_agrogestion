import '../../../core/format.dart';
import '../../../core/widgets/chips.dart';

String plantingStatusLabel(String status) => switch (status) {
  'en_curso' => 'En curso',
  'planeada' => 'Planeada',
  'cerrada' => 'Cerrada',
  'cancelada' => 'Cancelada',
  _ => humanize(status),
};

Tone plantingStatusTone(String status) => switch (status) {
  'en_curso' => Tone.ok,
  'planeada' => Tone.info,
  _ => Tone.neutral,
};

String phaseLabel(String phase) => switch (phase) {
  'preparacion' => 'Preparación del terreno',
  'siembra' => 'Siembra',
  'mantenimiento' => 'Mantenimiento',
  'cosecha' => 'Cosecha',
  'poscosecha' => 'Poscosecha',
  'renovacion' => 'Renovación',
  _ => humanize(phase),
};

String cycleTypeLabel(String type) => switch (type) {
  'levante' => 'Levante',
  'produccion' => 'Producción',
  'renovacion' => 'Renovación',
  _ => humanize(type),
};

String methodLabel(String method) => switch (method) {
  'semilla' => 'Semilla',
  'esqueje' => 'Esqueje',
  'estaca' => 'Estaca',
  'injerto' => 'Injerto',
  'hijuelo' => 'Hijuelo',
  'acodo' => 'Acodo',
  'in_vitro' => 'In vitro',
  _ => humanize(method),
};

const plantingMethods = [
  'semilla',
  'esqueje',
  'estaca',
  'injerto',
  'hijuelo',
  'acodo',
  'in_vitro',
];

Tone susceptibilityTone(String level) => switch (level) {
  'alta' => Tone.danger,
  'media' => Tone.warn,
  _ => Tone.neutral,
};
