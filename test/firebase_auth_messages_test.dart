import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/auth/data/firebase_auth_messages.dart';

void main() {
  group('mensajeFirebase (auth)', () {
    String msg(String code) =>
        mensajeFirebase(FirebaseAuthException(code: code));

    test('credenciales inválidas', () {
      expect(msg('user-not-found'), 'Correo o contraseña incorrectos.');
      expect(msg('wrong-password'), 'Correo o contraseña incorrectos.');
      expect(msg('invalid-credential'), 'Correo o contraseña incorrectos.');
    });

    test('correo en uso', () {
      expect(
        msg('email-already-in-use'),
        'Este correo ya está registrado. Prueba iniciando sesión.',
      );
    });

    test('contraseña débil', () {
      expect(
        msg('weak-password'),
        'La contraseña debe tener al menos 6 caracteres.',
      );
    });

    test('red caída', () {
      expect(msg('network-request-failed'), contains('Sin conexión'));
      expect(msg('timeout'), contains('Sin conexión'));
    });

    test('demasiados intentos', () {
      expect(msg('too-many-requests'), contains('Demasiados intentos'));
    });

    test('cuenta deshabilitada', () {
      expect(msg('user-disabled'), contains('deshabilitada'));
    });

    test('operación no permitida', () {
      expect(msg('operation-not-allowed'), contains('no está habilitado'));
    });

    test('cuenta existente con otro proveedor', () {
      expect(
        msg('account-exists-with-different-credential'),
        contains('Ya existe una cuenta con este correo usando contraseña'),
      );
    });

    test('inicio de sesión cancelado', () {
      expect(msg('web-context-canceled'), 'Inicio de sesión cancelado.');
      expect(msg('web-context-cancelled'), 'Inicio de sesión cancelado.');
      expect(msg('cancelled'), 'Inicio de sesión cancelado.');
      expect(msg('canceled'), 'Inicio de sesión cancelado.');
    });

    test('fallo del selector nativo de Google', () {
      expect(
        msg('google-sign-in-failed'),
        'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
      );
    });

    test('error desconocido conserva el código', () {
      expect(msg('algo-raro'), contains('algo-raro'));
    });
  });

  group('mensajeFirebase (firestore)', () {
    test('permiso denegado', () {
      expect(
        mensajeFirebase(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        ),
        contains('No tienes permiso'),
      );
    });

    test('servicio ocupado', () {
      expect(
        mensajeFirebase(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        ),
        contains('ocupado'),
      );
    });
  });

  test('error no-Firebase genérico', () {
    expect(mensajeFirebase(StateError('x')), contains('inesperado'));
  });
}
