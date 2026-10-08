import 'package:flutter/material.dart';

import '../../../core/widgets/chips.dart';

IconData riskIcon(String type) => switch (type) {
  'clima' => Icons.cloud_outlined,
  'plaga' => Icons.bug_report_outlined,
  'enfermedad' => Icons.coronavirus_outlined,
  _ => Icons.warning_amber_rounded,
};

Tone severityTone(String severity) => switch (severity) {
  'severa' => Tone.danger,
  'moderada' => Tone.warn,
  _ => Tone.neutral,
};
