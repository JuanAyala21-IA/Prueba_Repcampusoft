import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/app.dart';
import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/reportes/data/providers/reporte_providers.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';

import '../../fakes/fake_auth_repository.dart';

class _SesionEstudianteFake extends SesionController {
  @override
  Sesion build() => Sesion.rolAplicado(
    uid: 'uid-estudiante',
    correo: 'estudiante@uts.edu.co',
    rol: RolEnum.persona,
  );

  /// Simula una nueva emisión de la sesión (por ejemplo, al refrescar el
  /// perfil o el token) manteniendo el mismo rol.
  void emitirNuevaSesion({String correo = 'estudiante@uts.edu.co'}) {
    state = Sesion.rolAplicado(
      uid: 'uid-estudiante',
      correo: correo,
      rol: RolEnum.persona,
    );
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'un cambio de sesión no reinicia la pantalla actual (Tus reportes)',
    (tester) async {
      final _SesionEstudianteFake sesionFake = _SesionEstudianteFake();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith(() => sesionFake),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            misReportesProvider.overrideWith(
              (ref) => Stream.value(<Reporte>[]),
            ),
          ],
          child: const RepcampusoftApp(),
        ),
      );
      await tester.pumpAndSettle();

      // El gate lleva al dashboard de estudiante.
      expect(find.text('Reportar daños'), findsOneWidget);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(RepcampusoftApp)),
      );
      container.read(routerProvider).push(AppRoutes.misReportes);
      await tester.pumpAndSettle();
      expect(find.text('Tus Reportes'), findsOneWidget);

      // Emite una sesión nueva con el mismo rol (refresco de token/perfil).
      sesionFake.emitirNuevaSesion(correo: 'estudiante.actualizado@uts.edu.co');
      await tester.pumpAndSettle();

      // La pantalla sigue siendo la misma: no se recarga ni vuelve al inicio.
      expect(find.text('Tus Reportes'), findsOneWidget);
      expect(find.text('Reportar daños'), findsNothing);
    },
  );
}
