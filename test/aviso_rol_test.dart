import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/presentation/auth_widgets.dart';

void main() {
  group('avisoRolAsignado', () {
    test('sin rol intentado: solo informa el rol asignado', () {
      expect(
        avisoRolAsignado(intentado: null, asignado: RolEnum.persona),
        'Tu rol asignado es: Persona.',
      );
    });

    test('rol intentado igual al asignado: sin aviso de denegación', () {
      expect(
        avisoRolAsignado(intentado: RolEnum.administrativo, asignado: RolEnum.administrativo),
        'Tu rol asignado es: Administrativo.',
      );
    });

    test('administrativo no autorizado: indica la denegación y el rol real', () {
      expect(
        avisoRolAsignado(intentado: RolEnum.administrativo, asignado: RolEnum.persona),
        'No tienes autorización para Administrativo. Tu rol asignado es: Persona.',
      );
    });
  });
}