import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/usuarios/data/providers/usuario_providers.dart';
import 'package:repcampusoft/features/usuarios/presentation/manage_users_screen.dart';

import '../../../fakes/fake_usuario_repository.dart';

Usuario _usuario({
  required String uid,
  required String nombre,
  required RolEnum rol,
}) {
  return Usuario(uid: uid, nombre: nombre, correo: '$uid@uts.edu.co', rol: rol);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget crearApp(FakeUsuarioRepository repo) {
    final router = GoRouter(
      initialLocation: AppRoutes.gestionUsuarios,
      routes: [
        GoRoute(
          path: AppRoutes.gestionUsuarios,
          builder: (_, _) => const ManageUsersScreen(),
        ),
        GoRoute(
          path: AppRoutes.crearUsuario,
          builder: (_, _) => const Scaffold(body: Text('CREAR_USUARIO')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [usuarioRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ManageUsersScreen (superadministrador)', () {
    testWidgets('lista los usuarios activos con su rol', (tester) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
          _usuario(
            uid: 'adm',
            nombre: 'Luis Administrativo',
            rol: RolEnum.administrativo,
          ),
          _usuario(
            uid: 'man',
            nombre: 'Marta Mantenimiento',
            rol: RolEnum.mantenimiento,
          ),
        ],
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Ana Estudiante'), findsOneWidget);
      expect(find.text('Luis Administrativo'), findsOneWidget);
      expect(find.text('Marta Mantenimiento'), findsOneWidget);
      expect(find.text('Estudiante'), findsOneWidget);
      expect(find.text('Administrativo'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
      // Todos son deshabilitables.
      expect(find.byTooltip('Deshabilitar cuenta'), findsNWidgets(3));
    });

    testWidgets('el propio superadministrador no se puede deshabilitar', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(
            uid: 'super',
            nombre: 'Súper Admin',
            rol: RolEnum.superadministrador,
          ),
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
        ],
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Súper Admin'), findsOneWidget);
      expect(find.byTooltip('Deshabilitar cuenta'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío cuando no hay usuarios', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository();

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('No hay usuarios activos'), findsOneWidget);
    });

    testWidgets('muestra error si falla la carga', (tester) async {
      final repo = FakeUsuarioRepository()..emitirError('sin permisos');

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('No se pudieron cargar los usuarios'), findsOneWidget);
      expect(find.textContaining('sin permisos'), findsOneWidget);
    });

    testWidgets('busca usuarios por correo sin distinguir mayúsculas', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
          _usuario(
            uid: 'adm',
            nombre: 'Luis Administrativo',
            rol: RolEnum.administrativo,
          ),
          _usuario(
            uid: 'man',
            nombre: 'Marta Mantenimiento',
            rol: RolEnum.mantenimiento,
          ),
        ],
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'MAN@UTS');
      await tester.pumpAndSettle();

      expect(find.text('Marta Mantenimiento'), findsOneWidget);
      expect(find.text('Ana Estudiante'), findsNothing);
      expect(find.text('Luis Administrativo'), findsNothing);
    });

    testWidgets('muestra "Sin resultados" si ningún correo coincide', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
        ],
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nadie@uts.edu.co');
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.text('No hay usuarios con ese correo.'), findsOneWidget);
    });

    testWidgets('el botón Crear usuario navega al formulario', (tester) async {
      final repo = FakeUsuarioRepository();

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear usuario'));
      await tester.pumpAndSettle();

      expect(find.text('CREAR_USUARIO'), findsOneWidget);
    });

    testWidgets('confirmar el diálogo deshabilita la cuenta', (tester) async {
      final usuario = _usuario(
        uid: 'est',
        nombre: 'Ana Estudiante',
        rol: RolEnum.persona,
      );
      final repo = FakeUsuarioRepository(usuarios: [usuario]);

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deshabilitar cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Deshabilitar cuenta'), findsOneWidget);
      expect(find.textContaining('Ana Estudiante'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, 'Deshabilitar'));
      await tester.pumpAndSettle();

      expect(repo.eliminados, hasLength(1));
      expect(repo.eliminados.single.uid, 'est');
      expect(find.text('Cuenta deshabilitada correctamente.'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no deshabilita la cuenta', (tester) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
        ],
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deshabilitar cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.eliminados, isEmpty);
    });

    testWidgets('si la deshabilitación falla muestra el mensaje', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository(
        usuarios: [
          _usuario(uid: 'est', nombre: 'Ana Estudiante', rol: RolEnum.persona),
        ],
        resultadoEliminacion: const Failure<void>('No autorizado'),
      );

      await tester.pumpWidget(crearApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deshabilitar cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Deshabilitar'));
      await tester.pumpAndSettle();

      expect(find.text('No autorizado'), findsOneWidget);
    });
  });
}
