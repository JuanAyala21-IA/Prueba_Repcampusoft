import 'falla_app.dart';

/// Contrato del repositorio de fallas de la app (buzón sin estados).
abstract class FallasAppRepository {
  /// Guarda un reporte de falla enviado por el usuario autenticado.
  Future<void> reportar({required String mensaje, String? pantalla});

  /// Observa todas las fallas reportadas (solo administrativo).
  Stream<List<FallaApp>> watchFallas();
}
