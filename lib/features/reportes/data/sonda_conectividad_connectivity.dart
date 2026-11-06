import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/servicio_adjuntar_foto.dart';

/// Sonda real de conectividad (RNF-04/RNF-05, pantallas 1/6/7/8/10).
///
/// Voice-pattern de Fases 1-4: la UI importa la abstraccion [SondaConectividad]
/// (dominio); la dependencia concreta `connectivity_plus` vive solo en esta
/// capa de datos.
class SondaConectividadConnectivity implements SondaConectividad {
  SondaConectividadConnectivity({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hayConexion() async {
    final List<ConnectivityResult> resultados = await _connectivity
        .checkConnectivity();
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}
