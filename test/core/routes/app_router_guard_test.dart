import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';

/// Gate de navegación por rol (arquitectura §5.3).
///
/// El superadministrador solo debe llegar a gestión de usuarios, fallas de la
/// app y a la consulta de reportes; los reportes se actualizan únicamente con
/// los roles administrativo/mantenimiento.
void main() {
  Sesion sesionCon(RolEnum rol) => Sesion.rolAplicado(
    uid: 'uid-${rol.nombreFirestore}',
    correo: '${rol.nombreFirestore}@uts.edu.co',
    rol: rol,
  );

  group('Gate sin sesión', () {
    const Sesion sesion = Sesion.sinSesion();

    test('permite las rutas públicas', () {
      for (final ruta in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.info,
        AppRoutes.registro,
        AppRoutes.recuperar,
      ]) {
        expect(redireccionPorSesion(sesion, ruta), isNull, reason: ruta);
      }
    });

    test('manda a welcome desde rutas privadas', () {
      expect(
        redireccionPorSesion(sesion, AppRoutes.inicioEstudiante),
        AppRoutes.welcome,
      );
      expect(
        redireccionPorSesion(sesion, AppRoutes.gestionUsuarios),
        AppRoutes.welcome,
      );
    });
  });

  group('Gate de verificación y perfil', () {
    test('correoPendiente solo deja verificar-correo', () {
      const Sesion sesion = Sesion.correoPendiente(
        uid: 'uid',
        correo: 'a@uts.edu.co',
      );
      expect(redireccionPorSesion(sesion, AppRoutes.verificarCorreo), isNull);
      expect(
        redireccionPorSesion(sesion, AppRoutes.inicioEstudiante),
        AppRoutes.verificarCorreo,
      );
    });

    test('rolPendiente solo deja completar-perfil', () {
      const Sesion sesion = Sesion.rolPendiente(
        uid: 'uid',
        correo: 'a@uts.edu.co',
      );
      expect(redireccionPorSesion(sesion, AppRoutes.completarPerfil), isNull);
      expect(
        redireccionPorSesion(sesion, AppRoutes.inicioEstudiante),
        AppRoutes.completarPerfil,
      );
    });
  });

  group('Gate de cuenta deshabilitada', () {
    const Sesion sesion = Sesion.cuentaBloqueada(
      uid: 'uid',
      correo: 'a@uts.edu.co',
    );

    test('solo permite la pantalla de cuenta bloqueada', () {
      expect(redireccionPorSesion(sesion, AppRoutes.cuentaBloqueada), isNull);
      for (final ruta in [
        AppRoutes.inicioEstudiante,
        AppRoutes.inicioAdmin,
        AppRoutes.gestionUsuarios,
        AppRoutes.login,
      ]) {
        expect(
          redireccionPorSesion(sesion, ruta),
          AppRoutes.cuentaBloqueada,
          reason: ruta,
        );
      }
    });
  });

  group('Gate de persona (estudiante)', () {
    final Sesion sesion = sesionCon(RolEnum.persona);

    test('permite sus módulos y el detalle de un reporte', () {
      for (final ruta in [
        AppRoutes.inicioEstudiante,
        AppRoutes.perfilEstudiante,
        AppRoutes.reportarDanos,
        AppRoutes.misReportes,
        AppRoutes.notificacionesEstudiante,
        AppRoutes.editarPerfil,
        AppRoutes.cambiarContrasena,
        AppRoutes.reportarFalla,
        '${AppRoutes.detalleReporte}/abc123',
      ]) {
        expect(redireccionPorSesion(sesion, ruta), isNull, reason: ruta);
      }
    });

    test('no accede a módulos de gestión ni de superadministrador', () {
      for (final ruta in [
        AppRoutes.inicioAdmin,
        AppRoutes.danosReportados,
        AppRoutes.misReportesAsignados,
        AppRoutes.gestionReporte,
        AppRoutes.notificacionesAdmin,
        AppRoutes.gestionUsuarios,
        AppRoutes.crearUsuario,
        AppRoutes.exportarReportes,
        AppRoutes.fallasApp,
      ]) {
        expect(
          redireccionPorSesion(sesion, ruta),
          AppRoutes.inicioEstudiante,
          reason: ruta,
        );
      }
    });
  });

  group('Gate de administrativo y mantenimiento', () {
    for (final rol in [RolEnum.administrativo, RolEnum.mantenimiento]) {
      final Sesion sesion = sesionCon(rol);

      test('${rol.nombreFirestore}: gestiona reportes', () {
        for (final ruta in [
          AppRoutes.inicioAdmin,
          AppRoutes.perfilAdmin,
          AppRoutes.danosReportados,
          AppRoutes.misReportesAsignados,
          AppRoutes.gestionReporte,
          AppRoutes.notificacionesAdmin,
          AppRoutes.editarPerfil,
          AppRoutes.cambiarContrasena,
          AppRoutes.reportarFalla,
        ]) {
          expect(redireccionPorSesion(sesion, ruta), isNull, reason: ruta);
        }
      });

      test('${rol.nombreFirestore}: no accede a gestión de usuarios ni '
          'a fallas de la app', () {
        for (final ruta in [
          AppRoutes.gestionUsuarios,
          AppRoutes.crearUsuario,
          AppRoutes.exportarReportes,
          AppRoutes.fallasApp,
          AppRoutes.inicioEstudiante,
          AppRoutes.reportarDanos,
        ]) {
          expect(
            redireccionPorSesion(sesion, ruta),
            AppRoutes.inicioAdmin,
            reason: ruta,
          );
        }
      });
    }
  });

  group('Gate de superadministrador', () {
    final Sesion sesion = sesionCon(RolEnum.superadministrador);

    test('accede a usuarios, fallas de la app y consulta de reportes', () {
      for (final ruta in [
        AppRoutes.inicioAdmin,
        AppRoutes.perfilAdmin,
        AppRoutes.danosReportados,
        AppRoutes.gestionReporte,
        AppRoutes.notificacionesAdmin,
        AppRoutes.fallasApp,
        AppRoutes.gestionUsuarios,
        AppRoutes.crearUsuario,
        AppRoutes.exportarReportes,
        AppRoutes.editarPerfil,
        AppRoutes.cambiarContrasena,
        AppRoutes.reportarFalla,
      ]) {
        expect(redireccionPorSesion(sesion, ruta), isNull, reason: ruta);
      }
    });

    test('no accede a los módulos de estudiante', () {
      for (final ruta in [
        AppRoutes.inicioEstudiante,
        AppRoutes.reportarDanos,
        AppRoutes.misReportes,
        AppRoutes.notificacionesEstudiante,
      ]) {
        expect(
          redireccionPorSesion(sesion, ruta),
          AppRoutes.inicioAdmin,
          reason: ruta,
        );
      }
    });
  });
}
