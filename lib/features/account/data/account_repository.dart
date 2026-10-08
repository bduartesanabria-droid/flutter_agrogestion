import '../../../core/api/api_client.dart';
import '../../../core/api/backend.dart';

class Policy {
  const Policy({
    required this.version,
    required this.dataUsed,
    required this.purposes,
    required this.rights,
  });

  final String version;
  final List<String> dataUsed;
  final List<String> purposes;
  final List<String> rights;

  factory Policy.fromJson(Json json) => Policy(
    version: json['version'] as String? ?? '',
    dataUsed: (json['datos_que_usamos'] as List? ?? const []).cast<String>(),
    purposes: (json['para_que'] as List? ?? const []).cast<String>(),
    rights: (json['sus_derechos'] as List? ?? const []).cast<String>(),
  );
}

class Consent {
  const Consent({
    required this.version,
    required this.acceptedAt,
    required this.aiTransfer,
  });

  final String version;
  final String acceptedAt;
  final bool aiTransfer;

  factory Consent.fromJson(Json json) => Consent(
    version: json['version_politica'] as String? ?? '',
    acceptedAt: json['aceptado_en'] as String? ?? '',
    aiTransfer: json['acepta_transferencia_ia'] == true,
  );
}

class AccountRepository {
  const AccountRepository(this._backend);

  final Backend _backend;

  Future<Policy> policy() async =>
      Policy.fromJson(await _backend.getJson('politica'));

  Future<Consent?> consent() async {
    try {
      return Consent.fromJson(await _backend.getJson('cuenta/consentimiento'));
    } on ApiException catch (error) {
      if (error.code == 'CONSENTIMIENTO_PENDIENTE' || error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> accept({required String version, required bool aiTransfer}) =>
      _backend.post(
        'cuenta/consentimiento',
        body: {
          'version_politica': version,
          'acepta_tratamiento': true,
          'acepta_transferencia_ia': aiTransfer,
        },
      );
}
