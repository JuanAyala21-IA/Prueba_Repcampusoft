import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/assigned_reports_screen.dart';
import '../../features/admin/presentation/manage_report_screen.dart';
import '../../features/admin/presentation/reported_damages_screen.dart';
import '../../features/auth/domain/rol_enum.dart';
import '../../features/auth/presentation/about_screen.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/fallas_app/presentation/fallas_app_screen.dart';
import '../../features/fallas_app/presentation/reportar_falla_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/blocked_account_screen.dart';
import '../../features/home/presentation/admin_home_screen.dart';
import '../../features/home/presentation/student_home_screen.dart';
import '../../features/notificaciones/presentation/admin_notifications_screen.dart';
import '../../features/notificaciones/presentation/student_notifications_screen.dart';
import '../../features/perfil/presentation/admin_profile_screen.dart';
import '../../features/perfil/presentation/edit_profile_screen.dart';
import '../../features/perfil/presentation/student_profile_screen.dart';
import '../../features/reportes/presentation/my_reports_screen.dart';
import '../../features/reportes/presentation/report_damage_screen.dart';
import '../../features/reportes/presentation/report_detail_screen.dart';
import '../../features/usuarios/presentation/create_user_screen.dart';
import '../../features/usuarios/presentation/manage_users_screen.dart';
import 'session_provider.dart';

/// Rutas centrales de la app (arquitectura §5.1/§5.2/§5.3).
abstract final class AppRoutes {
  // Públicas.
  static const String welcome = '/';
  static const String login = '/login';
  static const String info = '/sobre-repcampusoft';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar-password';
  static const String verificarCorreo = '/verificar-correo';
  static const String completarPerfil = '/completar-perfil';
  static const String cuentaBloqueada = '/cuenta-bloqueada';

  // Estudiante / Persona.
  static const String inicioEstudiante = '/inicio-estudiante';
  static const String perfilEstudiante = '/perfil-estudiante';
  static const String reportarDanos = '/reportar-danos';
  static const String misReportes = '/mis-reportes';
  static const String detalleReporte = '/detalle-reporte';
  static const String notificacionesEstudiante = '/notificaciones-estudiante';

  // Administrativo.
  static const String inicioAdmin = '/inicio-admin';
  static const String perfilAdmin = '/perfil-admin';
  static const String danosReportados = '/danos-reportados';
  static const String misReportesAsignados = '/mis-reportes-asignados';
  static const String gestionReporte = '/gestion-reporte';
  static const String notificacionesAdmin = '/notificaciones-admin';

  // Común autenticado.
  static const String editarPerfil = '/editar-perfil';
  static const String cambiarContrasena = '/cambiar-contrasena';

  // Fallas de la app (buzón sin estados).
  static const String reportarFalla = '/reportar-falla';
  static const String fallasApp = '/fallas-app';

  // Superadministrador.
  static const String gestionUsuarios = '/gestion-usuarios';
  static const String crearUsuario = '/crear-usuario';
}

final routerProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) => _redirigir(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.info, builder: (_, _) => const AboutScreen()),
      GoRoute(
        path: AppRoutes.registro,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperar,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificarCorreo,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.completarPerfil,
        builder: (_, _) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.cuentaBloqueada,
        builder: (_, _) => const BlockedAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.inicioEstudiante,
        builder: (_, _) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.inicioAdmin,
        builder: (_, _) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.perfilEstudiante,
        builder: (_, _) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.perfilAdmin,
        builder: (_, _) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editarPerfil,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.cambiarContrasena,
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportarFalla,
        builder: (_, _) => const ReportarFallaScreen(),
      ),
      GoRoute(
        path: AppRoutes.fallasApp,
        builder: (_, _) => const FallasAppScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportarDanos,
        builder: (_, _) => const ReportDamageScreen(),
      ),
      GoRoute(
        path: AppRoutes.misReportes,
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.detalleReporte}/:reportId',
        builder: (_, _) => const ReportDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificacionesEstudiante,
        builder: (_, _) => const StudentNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.danosReportados,
        builder: (_, _) => const ReportedDamagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.misReportesAsignados,
        builder: (_, _) => const AssignedReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gestionReporte,
        builder: (_, _) => const ManageReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificacionesAdmin,
        builder: (_, _) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gestionUsuarios,
        builder: (_, _) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.crearUsuario,
        builder: (_, _) => const CreateUserScreen(),
      ),
    ],
  );

  // La sesión cambia al iniciar/cerrar sesión o al refrescar el perfil. Se
  // re-evalúa el gate con `refresh()` en lugar de recrear el GoRouter: recrearlo
  // reiniciaba la navegación y hacía que la pantalla actual se recargara sola.
  ref.listen<Sesion>(sesionProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

/// Gate de navegación del §5.3: sesión → correo verificado → perfil → rol.
String? _redirigir(Ref ref, GoRouterState estado) {
  final String ruta = estado.uri.path.isEmpty
      ? AppRoutes.welcome
      : estado.uri.path;
  return redireccionPorSesion(ref.read(sesionProvider), ruta);
}

/// Resuelve la ruta permitida para una [sesion] y una [ruta] solicitada.
///
/// Se expone para probar el gate por rol sin levantar las pantallas reales
/// (que dependen de Firebase). Devuelve `null` cuando la ruta es válida.
@visibleForTesting
String? redireccionPorSesion(Sesion sesion, String ruta) {
  const Set<String> rutasPublicas = {
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.info,
    AppRoutes.registro,
    AppRoutes.recuperar,
  };

  switch (sesion.estado) {
    case SesionEstado.sinSesion:
      return rutasPublicas.contains(ruta) ? null : AppRoutes.welcome;

    case SesionEstado.correoPendiente:
      return ruta == AppRoutes.verificarCorreo
          ? null
          : AppRoutes.verificarCorreo;

    case SesionEstado.rolPendiente:
      return ruta == AppRoutes.completarPerfil
          ? null
          : AppRoutes.completarPerfil;

    case SesionEstado.rolAplicado:
      final RolEnum? rol = sesion.rol;
      final Set<String> permitidas = switch (rol) {
        RolEnum.administrativo || RolEnum.mantenimiento => rutasGestion,
        RolEnum.superadministrador => rutasSuperadministrador,
        _ => rutasPersona,
      };
      // Coincidencia exacta o de subruta (ej: /detalle-reporte/:reportId).
      final bool permitida = permitidas.any(
        (p) => ruta == p || ruta.startsWith('$p/'),
      );
      if (permitida) return null;
      return switch (rol) {
        RolEnum.administrativo ||
        RolEnum.mantenimiento ||
        RolEnum.superadministrador => AppRoutes.inicioAdmin,
        _ => AppRoutes.inicioEstudiante,
      };

    case SesionEstado.cuentaBloqueada:
      return ruta == AppRoutes.cuentaBloqueada
          ? null
          : AppRoutes.cuentaBloqueada;
  }
}

const Set<String> rutasPersona = {
  AppRoutes.inicioEstudiante,
  AppRoutes.perfilEstudiante,
  AppRoutes.reportarDanos,
  AppRoutes.misReportes,
  AppRoutes.detalleReporte,
  AppRoutes.notificacionesEstudiante,
  AppRoutes.editarPerfil,
  AppRoutes.cambiarContrasena,
  AppRoutes.reportarFalla,
};

const Set<String> rutasGestion = {
  AppRoutes.inicioAdmin,
  AppRoutes.perfilAdmin,
  AppRoutes.danosReportados,
  AppRoutes.misReportesAsignados,
  AppRoutes.gestionReporte,
  AppRoutes.notificacionesAdmin,
  AppRoutes.editarPerfil,
  AppRoutes.cambiarContrasena,
  AppRoutes.reportarFalla,
};

const Set<String> rutasSuperadministrador = {
  AppRoutes.inicioAdmin,
  AppRoutes.perfilAdmin,
  AppRoutes.danosReportados,
  AppRoutes.gestionReporte,
  AppRoutes.notificacionesAdmin,
  AppRoutes.editarPerfil,
  AppRoutes.cambiarContrasena,
  AppRoutes.reportarFalla,
  AppRoutes.fallasApp,
  AppRoutes.gestionUsuarios,
  AppRoutes.crearUsuario,
};
