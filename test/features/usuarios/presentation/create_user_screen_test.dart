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
import 'package:repcampusoft/features/usuarios/presentation/create_user_screen.dart';
import 'package:repcampusoft/shared/widgets/fields.dart';

import '../../../fakes/fake_usuario_repository.dart';

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
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.crearUsuario),
                child: const Text('ABRIR_FORMULARIO'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.crearUsuario,
          builder: (_, _) => const CreateUserScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [usuarioRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> abrirFormulario(
    WidgetTester tester,
    FakeUsuarioRepository repo,
  ) async {
    await tester.pumpWidget(crearApp(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABRIR_FORMULARIO'));
    await tester.pumpAndSettle();
  }

  Future<void> completarDatos(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(LabelledField, 'Nombre completo'),
      'Ana Estudiante',
    );
    await tester.enterText(
      find.widgetWithText(LabelledField, 'Correo institucional'),
      'ana@uts.edu.co',
    );
    await tester.enterText(
      find.widgetWithText(LabelledField, 'Contraseña inicial'),
      'secreta123',
    );
    await tester.pump();
  }

  group('CreateUserScreen (superadministrador)', () {
    testWidgets('solo ofrece los roles gestionables', (tester) async {
      final repo = FakeUsuarioRepository();
      await abrirFormulario(tester, repo);

      expect(find.text('Estudiante'), findsOneWidget);
      expect(find.text('Administrativo'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
      expect(find.text('Superadministrador'), findsNothing);
      // Por defecto se crea un estudiante: sin campos de personal.
      expect(find.text('Cargo'), findsNothing);
      expect(find.text('Dependencia / Área'), findsNothing);
    });

    testWidgets('elegir un rol de personal muestra cargo y dependencia', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository();
      await abrirFormulario(tester, repo);

      await tester.tap(find.text('Administrativo'));
      await tester.pumpAndSettle();

      expect(find.text('Cargo'), findsOneWidget);
      expect(find.text('Dependencia / Área'), findsOneWidget);
    });

    testWidgets('crea la cuenta con el rol seleccionado', (tester) async {
      final repo = FakeUsuarioRepository();
      await abrirFormulario(tester, repo);

      await tester.tap(find.text('Mantenimiento'));
      await tester.pumpAndSettle();
      await completarDatos(tester);

      final boton = find.text('CREAR USUARIO');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(repo.creaciones, hasLength(1));
      expect(repo.creaciones.single.rol, RolEnum.mantenimiento);
      expect(repo.creaciones.single.nombre, 'Ana Estudiante');
      expect(repo.creaciones.single.correo, 'ana@uts.edu.co');
      expect(repo.creaciones.single.contrasena, 'secreta123');

      expect(find.text('Cuenta creada'), findsOneWidget);
      expect(find.textContaining('Mantenimiento'), findsWidgets);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      // Vuelve al panel de gestión de usuarios.
      expect(find.text('ABRIR_FORMULARIO'), findsOneWidget);
    });

    testWidgets('no envía el formulario si faltan datos', (tester) async {
      final repo = FakeUsuarioRepository();
      await abrirFormulario(tester, repo);

      final boton = find.text('CREAR USUARIO');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(repo.creaciones, isEmpty);
      expect(find.text('Este campo es obligatorio'), findsOneWidget);
    });

    testWidgets('muestra el error del repositorio en un SnackBar', (
      tester,
    ) async {
      final repo = FakeUsuarioRepository(
        resultadoCreacion: const Failure<Usuario>(
          'El correo ya está registrado.',
        ),
      );
      await abrirFormulario(tester, repo);
      await completarDatos(tester);

      final boton = find.text('CREAR USUARIO');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('El correo ya está registrado.'), findsOneWidget);
      expect(find.text('Cuenta creada'), findsNothing);
    });
  });
}
