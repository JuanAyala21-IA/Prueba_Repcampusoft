import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';

import 'fakes/fake_auth_repository.dart';

Future<void> pump() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer crearContainer(FakeAuthRepository fake) {
  final ProviderContainer container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
  );
  container.read(sesionProvider);
  return container;
}

void main() {
  test('registro crea cuenta, guarda intento y pasa a correoPendiente', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final String? error = await container.read(sesionProvider.notifier).registrar(
          nombre: 'Ana Torres',
          correo: 'Ana@Ejemplo.com',
          contrasena: 'secreta1',
          cargo: 'Estudiante',
          rolIntentado: RolEnum.persona,
        );
    expect(error, isNull);
    expect(fake.enviadoCorreoVerificacion, isTrue);

    await pump();
    final Sesion sesion = container.read(sesionProvider);
    expect(sesion.estado, SesionEstado.correoPendiente);
    expect(sesion.correo, 'ana@ejemplo.com');

    final intento = container.read(registroIntentadoProvider);
    expect(intento, isNotNull);
    expect(intento!.nombre, 'Ana Torres');
    expect(intento.rolIntentado, RolEnum.persona);
  });

  test('verificación sin whitelist asigna persona aunque intente administrativo', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container.read(sesionProvider.notifier).registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
          cargo: null,
          rolIntentado: RolEnum.administrativo,
        );
    fake.marcarVerificado('ana@ejemplo.com');

    final Result<RolEnum?> resultado =
        await container.read(sesionProvider.notifier).completarVerificacion();
    expect(resultado, isA<Success<RolEnum?>>());
    expect((resultado as Success<RolEnum?>).value, RolEnum.persona);

    await pump();
    final Sesion sesion = container.read(sesionProvider);
    expect(sesion.estado, SesionEstado.rolAplicado);
    expect(sesion.rol, RolEnum.persona);
    expect(container.read(registroIntentadoProvider), isNull);
  });

  test('verificación con whitelist asigna administrativo aunque intente persona', () async {
    final FakeAuthRepository fake = FakeAuthRepository(whitelist: {'admin@uts.edu.co'});
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container.read(sesionProvider.notifier).registrar(
          nombre: 'Jefe',
          correo: 'admin@uts.edu.co',
          contrasena: 'secreta1',
          cargo: 'Coord. Mantenimiento',
          rolIntentado: RolEnum.persona,
        );
    fake.marcarVerificado('admin@uts.edu.co');

    final Result<RolEnum?> resultado =
        await container.read(sesionProvider.notifier).completarVerificacion();
    expect((resultado as Success<RolEnum?>).value, RolEnum.administrativo);

    await pump();
    expect(container.read(sesionProvider).rol, RolEnum.administrativo);
  });

  test('login sin verificar pasa a correoPendiente', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container.read(sesionProvider.notifier).registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
          cargo: null,
          rolIntentado: RolEnum.persona,
        );
    await pump();

    final String? error = await container
        .read(sesionProvider.notifier)
        .iniciarSesion(correo: 'ana@ejemplo.com', contrasena: 'secreta1');
    expect(error, isNull);
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.correoPendiente);
  });

  test('login con perfil persistido vuelve al dashboard según rol', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final notifier = container.read(sesionProvider.notifier);
    await notifier.registrar(
      nombre: 'Ana',
      correo: 'ana@ejemplo.com',
      contrasena: 'secreta1',
      cargo: null,
      rolIntentado: RolEnum.persona,
    );
    fake.marcarVerificado('ana@ejemplo.com');
    await notifier.completarVerificacion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.rolAplicado);

    await notifier.cerrarSesion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);

    await notifier.iniciarSesion(correo: 'ana@ejemplo.com', contrasena: 'secreta1');
    await pump();
    final Sesion sesion = container.read(sesionProvider);
    expect(sesion.estado, SesionEstado.rolAplicado);
    expect(sesion.rol, RolEnum.persona);
  });

  test('cerrar sesión limpia el registro pendiente', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container.read(sesionProvider.notifier).registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
          cargo: null,
          rolIntentado: RolEnum.persona,
        );
    await pump();
    expect(container.read(registroIntentadoProvider), isNotNull);

    await container.read(sesionProvider.notifier).cerrarSesion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);
    expect(container.read(registroIntentadoProvider), isNull);
  });

  test('inicio de sesión con credenciales inválidas devuelve mensaje en español', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final String? error = await container
        .read(sesionProvider.notifier)
        .iniciarSesion(correo: 'nadie@ejemplo.com', contrasena: 'clave123');
    expect(error, 'Correo o contraseña incorrectos.');
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);
  });

  test('registro con correo existente devuelve mensaje en español', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    fake.correosRegistrados.add('ivan@ejemplo.com');
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final String? error = await container.read(sesionProvider.notifier).registrar(
          nombre: 'Iv',
          correo: 'ivan@ejemplo.com',
          contrasena: 'clave123',
          cargo: null,
          rolIntentado: RolEnum.persona,
        );
    expect(error, 'Este correo ya está registrado. Prueba iniciando sesión.');
  });
}