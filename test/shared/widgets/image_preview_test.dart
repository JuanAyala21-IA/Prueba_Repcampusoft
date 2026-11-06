import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/shared/widgets/image_preview.dart';

/// PNG de 1x1 transparente, suficiente para `Image.memory`.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  Widget crearApp({String? descripcion}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                mostrarImagenAmpliada(context, _png, descripcion: descripcion),
            child: const Text('AMPLIAR'),
          ),
        ),
      ),
    );
  }

  testWidgets('abre la imagen a pantalla completa con zoom y descripción', (
    tester,
  ) async {
    await tester.pumpWidget(crearApp(descripcion: 'Evidencia del daño'));

    await tester.tap(find.text('AMPLIAR'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Evidencia del daño'), findsOneWidget);
    expect(
      find.text('Pellizca o haz doble toque para hacer zoom'),
      findsOneWidget,
    );
    expect(find.byTooltip('Cerrar'), findsOneWidget);
  });

  testWidgets('el doble toque hace zoom y lo revierte', (tester) async {
    await tester.pumpWidget(crearApp());

    await tester.tap(find.text('AMPLIAR'));
    await tester.pumpAndSettle();

    final InteractiveViewer visor = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final TransformationController controlador =
        visor.transformationController!;

    expect(controlador.value.getMaxScaleOnAxis(), 1.0);

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();

    expect(controlador.value.getMaxScaleOnAxis(), greaterThan(1.0));

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();

    expect(controlador.value.getMaxScaleOnAxis(), 1.0);
  });

  testWidgets('el botón cerrar vuelve a la pantalla anterior', (tester) async {
    await tester.pumpWidget(crearApp());

    await tester.tap(find.text('AMPLIAR'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('AMPLIAR'), findsOneWidget);
  });
}
