import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/utils/mes_anio.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/notificaciones/data/providers/notificacion_providers.dart';
import 'package:repcampusoft/features/perfil/data/providers/perfil_providers.dart';

Usuario perfilConCreacion(DateTime? creadoEn) => Usuario(
  uid: 'uid-test',
  nombre: 'Usuario Test',
  correo: 'test@uts.edu.co',
  rol: RolEnum.persona,
  creadoEn: creadoEn,
);

Future<List<MesAnio>> leerMeses(Usuario? perfil) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [perfilUsuarioProvider.overrideWith((ref) async => perfil)],
  );
  addTearDown(container.dispose);
  await container.read(perfilUsuarioProvider.future);
  return container.read(mesesNotificacionesProvider);
}

void main() {
  test('los meses empiezan en el mes de creación de la cuenta', () async {
    final MesAnio actual = MesAnio.actual();
    final MesAnio haceTresMeses = actual.anterior.anterior.anterior;
    final DateTime creado = DateTime(haceTresMeses.anio, haceTresMeses.mes, 10);

    final List<MesAnio> meses = await leerMeses(perfilConCreacion(creado));

    expect(meses.first, actual);
    expect(meses.last, haceTresMeses);
    expect(meses.length, 4);
  });

  test('si la cuenta se creó este mes solo se ofrece el mes actual', () async {
    final MesAnio actual = MesAnio.actual();
    final DateTime creado = DateTime(actual.anio, actual.mes, 1);

    final List<MesAnio> meses = await leerMeses(perfilConCreacion(creado));

    expect(meses, <MesAnio>[actual]);
  });

  test('sin fecha de creación usa la ventana de 24 meses', () async {
    final List<MesAnio> meses = await leerMeses(perfilConCreacion(null));

    expect(meses.length, 24);
    expect(meses.first, MesAnio.actual());
  });

  test('una fecha futura se limita al mes actual', () async {
    final MesAnio actual = MesAnio.actual();
    final DateTime creado = DateTime(actual.anio + 1, actual.mes, 1);

    final List<MesAnio> meses = await leerMeses(perfilConCreacion(creado));

    expect(meses, <MesAnio>[actual]);
  });
}
