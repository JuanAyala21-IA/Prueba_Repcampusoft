import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/auth/domain/tipo_acceso.dart';
import 'package:repcampusoft/features/auth/presentation/auth_widgets.dart';

void main() {
  testWidgets('el selector de acceso muestra las dos opciones y notifica el '
      'cambio', (tester) async {
    TipoAcceso? seleccionado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TipoAccesoSelector(
            seleccionado: TipoAcceso.estudiante,
            onChanged: (acceso) => seleccionado = acceso,
          ),
        ),
      ),
    );

    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Administrativo'), findsOneWidget);

    await tester.tap(find.text('Administrativo'));
    await tester.pump();

    expect(seleccionado, TipoAcceso.administrativo);
  });

  testWidgets('el selector no cambia cuando está deshabilitado', (
    tester,
  ) async {
    var cambios = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TipoAccesoSelector(
            seleccionado: TipoAcceso.administrativo,
            habilitado: false,
            onChanged: (_) => cambios++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Estudiante'));
    await tester.pump();

    expect(cambios, 0);
  });
}
