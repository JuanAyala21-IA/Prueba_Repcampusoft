import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';

import 'fakes/fake_auth_repository.dart';

Future<void> pump() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer crearContainer(FakeAuthRepository fake) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      localNotificacionesServiceProvider.overrideWith(
        (ref) => FakeLocalNotificacionesService(),
      ),
    ],
  );
  container.read(sesionProvider);
  return container;
}

/// Fake no-op para tests: no inicializa flutter_local_notifications
class FakeLocalNotificacionesService implements LocalNotificacionesService {
  @override
  Future<void> inicializar() async {}
}

void main() {
  test(
    'registro crea cuenta, guarda intento y pasa a correoPendiente',
    () async {
      final FakeAuthRepository fake = FakeAuthRepository();
      final ProviderContainer container = crearContainer(fake);
      addTearDown(container.dispose);

      final String? error = await container
          .read(sesionProvider.notifier)
          .registrar(
            nombre: 'Ana Torres',
            correo: 'Ana@Ejemplo.com',
            contrasena: 'secreta1',
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
    },
  );

  test('verificación sin whitelist asigna persona', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container
        .read(sesionProvider.notifier)
        .registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
        );
    fake.marcarVerificado('ana@ejemplo.com');

    final Result<RolEnum?> resultado = await container
        .read(sesionProvider.notifier)
        .completarVerificacion();
    expect(resultado, isA<Success<RolEnum?>>());
    expect((resultado as Success<RolEnum?>).value, RolEnum.persona);

    await pump();
    final Sesion sesion = container.read(sesionProvider);
    expect(sesion.estado, SesionEstado.rolAplicado);
    expect(sesion.rol, RolEnum.persona);
    expect(container.read(registroIntentadoProvider), isNull);
  });

  test('verificación con correo sembrado asigna superadministrador', () async {
    final FakeAuthRepository fake = FakeAuthRepository(
      whitelist: {'super@uts.edu.co'},
    );
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container
        .read(sesionProvider.notifier)
        .registrar(
          nombre: 'Super',
          correo: 'super@uts.edu.co',
          contrasena: 'secreta1',
        );
    fake.marcarVerificado('super@uts.edu.co');

    final Result<RolEnum?> resultado = await container
        .read(sesionProvider.notifier)
        .completarVerificacion();
    expect((resultado as Success<RolEnum?>).value, RolEnum.superadministrador);

    await pump();
    expect(container.read(sesionProvider).rol, RolEnum.superadministrador);
  });

  test('login sin verificar pasa a correoPendiente', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container
        .read(sesionProvider.notifier)
        .registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
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
    );
    fake.marcarVerificado('ana@ejemplo.com');
    await notifier.completarVerificacion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.rolAplicado);

    await notifier.cerrarSesion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);

    await notifier.iniciarSesion(
      correo: 'ana@ejemplo.com',
      contrasena: 'secreta1',
    );
    await pump();
    final Sesion sesion = container.read(sesionProvider);
    expect(sesion.estado, SesionEstado.rolAplicado);
    expect(sesion.rol, RolEnum.persona);
  });

  test('cerrar sesión limpia el registro pendiente', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    await container
        .read(sesionProvider.notifier)
        .registrar(
          nombre: 'Ana',
          correo: 'ana@ejemplo.com',
          contrasena: 'secreta1',
        );
    await pump();
    expect(container.read(registroIntentadoProvider), isNotNull);

    await container.read(sesionProvider.notifier).cerrarSesion();
    await pump();
    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);
    expect(container.read(registroIntentadoProvider), isNull);
  });

  test(
    'inicio de sesión con credenciales inválidas devuelve mensaje en español',
    () async {
      final FakeAuthRepository fake = FakeAuthRepository();
      final ProviderContainer container = crearContainer(fake);
      addTearDown(container.dispose);

      final String? error = await container
          .read(sesionProvider.notifier)
          .iniciarSesion(correo: 'nadie@ejemplo.com', contrasena: 'clave123');
      expect(error, 'Correo o contraseña incorrectos.');
      await pump();
      expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);
    },
  );

  test('registro con correo existente devuelve mensaje en español', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    fake.correosRegistrados.add('ivan@ejemplo.com');
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final String? error = await container
        .read(sesionProvider.notifier)
        .registrar(
          nombre: 'Iv',
          correo: 'ivan@ejemplo.com',
          contrasena: 'clave123',
        );
    expect(error, 'Este correo ya está registrado. Prueba iniciando sesión.');
  });

  test(
    'Google sin perfil pasa a rolPendiente y permite completar el registro',
    () async {
      final FakeAuthRepository fake = FakeAuthRepository();
      // Se acepta cualquier cuenta de Google, no solo el dominio institucional.
      fake.correoGoogle = 'ana@gmail.com';
      fake.nombreGoogle = 'Ana Torres';
      final ProviderContainer container = crearContainer(fake);
      addTearDown(container.dispose);

      final String? error = await container
          .read(sesionProvider.notifier)
          .iniciarSesionConGoogle();
      expect(error, isNull);
      await pump();

      final Sesion pendiente = container.read(sesionProvider);
      expect(pendiente.estado, SesionEstado.rolPendiente);
      expect(pendiente.correo, 'ana@gmail.com');
      expect(pendiente.nombreSugerido, 'Ana Torres');

      final Result<RolEnum> resultado = await container
          .read(sesionProvider.notifier)
          .completarPerfil(
            nombre: 'Ana Torres',
            correo: 'ana@gmail.com',
            contrasena: 'secreta123',
          );
      expect(resultado, isA<Success<RolEnum>>());
      await pump();

      // Google: la contraseña queda registrada para iniciar sesión con correo.
      expect(fake.contrasenas['uid-google-ana@gmail.com'], 'secreta123');
      // El perfil se crea antes de vincular la contraseña, porque vincularla
      // hace que Firebase marque el correo como no verificado y la regla de
      // Firestore bloquearía `users/{uid}`.
      expect(fake.perfilExistiaAlAsignarContrasena, isTrue);

      final Sesion aplicada = container.read(sesionProvider);
      expect(aplicada.estado, SesionEstado.rolAplicado);
      expect(aplicada.rol, RolEnum.persona);
    },
  );

  test(
    'sesión Google persistida sin perfil pasa a rolPendiente en el gate',
    () async {
      final FakeAuthRepository fake = FakeAuthRepository();
      final ProviderContainer container = crearContainer(fake);
      addTearDown(container.dispose);

      // Simula una sesión que ya existía al abrir la app: el gate debe crear el
      // perfil pendiente sin cerrar la sesión de Google.
      await fake.iniciarSesionConGoogle();
      await pump();

      expect(container.read(sesionProvider).estado, SesionEstado.rolPendiente);
      expect(fake.usuarioActual(), isNotNull);
    },
  );

  test('Google cancelado devuelve mensaje y no deja sesión', () async {
    final FakeAuthRepository fake = FakeAuthRepository();
    fake.correoGoogle = null;
    final ProviderContainer container = crearContainer(fake);
    addTearDown(container.dispose);

    final String? error = await container
        .read(sesionProvider.notifier)
        .iniciarSesionConGoogle();
    expect(error, 'Inicio de sesión cancelado.');
    await pump();

    expect(container.read(sesionProvider).estado, SesionEstado.sinSesion);
  });
}
