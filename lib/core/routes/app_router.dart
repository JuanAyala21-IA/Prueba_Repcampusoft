import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/manage_report_screen.dart';
import '../../features/admin/presentation/reported_damages_screen.dart';
import '../../features/auth/domain/rol_enum.dart';
import '../../features/auth/presentation/about_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
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
import 'session_provider.dart';

/// Rutas centrales de la app (arquitectura §5.1/§5.2/§5.3).
abstract final class AppRoutes {
  // Públicas.
  static const String login = '/login';
  static const String info = '/sobre-repcampusoft';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar-password';
  static const String verificarCorreo = '/verificar-correo';
  static const String completarPerfil = '/completar-perfil';

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
  static const String gestionReporte = '/gestion-reporte';
  static const String notificacionesAdmin = '/notificaciones-admin';

  // Común autenticado.
  static const String editarPerfil = '/editar-perfil';
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(sesionProvider);
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) => _redirigir(ref, state),
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.info, builder: (_, _) => const AboutScreen()),
      GoRoute(path: AppRoutes.registro, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.recuperar, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.verificarCorreo, builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: AppRoutes.completarPerfil, builder: (_, _) => const CompleteProfileScreen()),
      GoRoute(path: AppRoutes.inicioEstudiante, builder: (_, _) => const StudentHomeScreen()),
      GoRoute(path: AppRoutes.inicioAdmin, builder: (_, _) => const AdminHomeScreen()),
      GoRoute(path: AppRoutes.perfilEstudiante, builder: (_, _) => const StudentProfileScreen()),
      GoRoute(path: AppRoutes.perfilAdmin, builder: (_, _) => const AdminProfileScreen()),
      GoRoute(path: AppRoutes.editarPerfil, builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.reportarDanos, builder: (_, _) => const ReportDamageScreen()),
      GoRoute(path: AppRoutes.misReportes, builder: (_, _) => const MyReportsScreen()),
      GoRoute(path: AppRoutes.detalleReporte, builder: (_, _) => const ReportDetailScreen()),
      GoRoute(
        path: AppRoutes.notificacionesEstudiante,
        builder: (_, _) => const StudentNotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.danosReportados, builder: (_, _) => const ReportedDamagesScreen()),
      GoRoute(path: AppRoutes.gestionReporte, builder: (_, _) => const ManageReportScreen()),
      GoRoute(
        path: AppRoutes.notificacionesAdmin,
        builder: (_, _) => const AdminNotificationsScreen(),
      ),
    ],
  );
});

/// Gate de navegación del §5.3: sesión → correo verificado → perfil → rol.
String? _redirigir(Ref ref, GoRouterState estado) {
  final Sesion sesion = ref.read(sesionProvider);
  final String ruta =
      estado.uri.path.isEmpty || estado.uri.path == '/' ? AppRoutes.login : estado.uri.path;

  const Set<String> rutasPublicas = {
    AppRoutes.login,
    AppRoutes.info,
    AppRoutes.registro,
    AppRoutes.recuperar,
  };

  switch (sesion.estado) {
    case SesionEstado.sinSesion:
      return rutasPublicas.contains(ruta) ? null : AppRoutes.login;

    case SesionEstado.correoPendiente:
      return ruta == AppRoutes.verificarCorreo ? null : AppRoutes.verificarCorreo;

    case SesionEstado.rolPendiente:
      return ruta == AppRoutes.completarPerfil ? null : AppRoutes.completarPerfil;

    case SesionEstado.rolAplicado:
      final bool esAdmin = sesion.rol == RolEnum.administrativo;
      final Set<String> permitidas = esAdmin ? rutasAdministrativo : rutasPersona;
      if (permitidas.contains(ruta)) return null;
      return esAdmin ? AppRoutes.inicioAdmin : AppRoutes.inicioEstudiante;
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
};

const Set<String> rutasAdministrativo = {
  AppRoutes.inicioAdmin,
  AppRoutes.perfilAdmin,
  AppRoutes.danosReportados,
  AppRoutes.gestionReporte,
  AppRoutes.notificacionesAdmin,
  AppRoutes.editarPerfil,
};