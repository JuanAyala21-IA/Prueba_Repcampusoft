import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/rol_enum.dart';

/// Estados de sesión según el gate de §5.3 de arquitectura.
enum SesionEstado {
  /// Sin autenticar: solo rutas públicas.
  sinSesion,

  /// Autenticado pero correo sin verificar (paso intermedio del gate).
  correoPendiente,

  /// Autenticado, correo verificado y rol aplicado.
  rolAplicado,
}

/// Modelo de sesión (Fase 3: simulado; reemplazado por Firebase Auth + `users/{uid}`).
class Sesion {
  const Sesion._(this.estado, this.rol);

  const Sesion.sinSesion() : this._(SesionEstado.sinSesion, null);
  const Sesion.correoPendiente() : this._(SesionEstado.correoPendiente, null);
  const Sesion.rolAplicado(RolEnum rol) : this._(SesionEstado.rolAplicado, rol);

  final SesionEstado estado;
  final RolEnum? rol;

  bool get autenticado => estado == SesionEstado.rolAplicado;
  bool get correoVerificado => estado != SesionEstado.correoPendiente;
}

/// Controlador de sesión simulado para la Fase 3 (datos de mock para navegación).
class SesionController extends Notifier<Sesion> {
  @override
  Sesion build() => const Sesion.sinSesion();

  void simularLogin(RolEnum rol) => state = Sesion.rolAplicado(rol);

  void simularCorreoPendiente() => state = const Sesion.correoPendiente();

  void cerrarSesion() => state = const Sesion.sinSesion();
}

final sesionProvider = NotifierProvider<SesionController, Sesion>(SesionController.new);