import '../../features/auth/domain/auth_session.dart';

class Access {
  const Access(this.session);

  final AuthSession session;

  String get role => session.role;
  bool get isAdmin => role == 'admin';
  bool get isFarmer => role == 'agricultor';
  bool get isAccountant => role == 'contador';
  bool get isExpert => role == 'experto';

  bool _has(String method, String route) => session.permissions.any(
    (p) => p.method == method && p.route.startsWith(route),
  );

  bool get seesProduction => _has('GET', '/siembras');
  bool get managesProduction => _has('POST', '/siembras');
  bool get managesCatalog => _has('GET', '/cultivos');
  bool get seesRisks => _has('GET', '/eventos-adversos');
  bool get seesAssistant => _has('GET', '/consultas');

  bool get seesMoney => isAdmin || isFarmer || isAccountant;
  bool get registersMoney => isAdmin || isFarmer || isAccountant;
  bool get seesProfit => isAdmin || isAccountant;
  bool get cancelsMoney => isAdmin || isAccountant;
  bool get paysWorkers => isAdmin || isAccountant;

  bool get seesWorkers => isAdmin || isFarmer || isAccountant;
  bool get managesWorkers => isAdmin || isFarmer;
  bool get managesInventory => isAdmin || isFarmer;
  bool get seesInventory => _has('GET', '/fincas/{finca_id}/insumos');
  bool get seesPayments => _has('GET', '/fincas/{finca_id}/jornales');
  bool get seesProcesses => _has('GET', '/fincas/{finca_id}/procesos');
  bool get createsFarms => isAdmin || isFarmer;
  bool get seesReports => !isExpert;
  bool get managesUsers => _has('POST', '/usuarios');
  bool get registersFieldWork => isAdmin || isFarmer;

  bool get canQuickRegister => registersFieldWork || registersMoney;

  String get roleLabel => switch (role) {
    'admin' => 'Administrador',
    'agricultor' => 'Agricultor',
    'contador' => 'Contador',
    'experto' => 'Experto',
    _ => role,
  };
}
