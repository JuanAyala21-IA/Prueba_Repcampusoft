import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/features/reportes/data/providers/reporte_providers.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/features/reportes/presentation/my_reports_screen.dart';
import 'package:repcampusoft/shared/widgets/report_card.dart';
import 'package:repcampusoft/shared/widgets/uts_header.dart';

void main() {
  group('MyReportsScreen widget tests', () {
    Widget createTestWidgetWithOverride(Override override) {
      return ProviderScope(
        // Sin reintentos automáticos: así el test puede observar el estado de
        // error estable y comprobar el botón "Reintentar".
        retry: (_, _) => null,
        overrides: [override],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.misReportes,
            routes: [
              GoRoute(
                path: AppRoutes.misReportes,
                builder: (_, _) => const MyReportsScreen(),
              ),
              GoRoute(
                path: '${AppRoutes.detalleReporte}/:reportId',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    Widget createTestWidget(Stream<List<Reporte>> reportesStream) {
      return createTestWidgetWithOverride(
        misReportesProvider.overrideWith((ref) => reportesStream),
      );
    }

    testWidgets('DEBUG: verifica widget tree completo', (tester) async {
      await tester.pumpWidget(createTestWidget(Stream.value(<Reporte>[])));
      await tester.pumpAndSettle();

      // Verificar que al menos el header se renderiza
      expect(find.byType(UtsHeader), findsOneWidget);
    });

    testWidgets(
      'con 2 reportes: muestra 2 ReportCard con StatusBadge correcto',
      (tester) async {
        final reportes = [
          Reporte(
            reporteId: 'r1',
            uid: 'user-1',
            correoAutor: 'user1@example.com',
            tipoDano: 'Silla dañada',
            tipoUbicacion: TipoEspacio.aula,
            edificio: 'Edificio A',
            piso: 'Piso 1',
            espacio: 'Salón 101',
            descripcion: 'Grieta en la silla',
            estado: EstadoReporte.pendiente,
            tieneFoto: false,
            creadoEn: DateTime(2026, 9, 8),
          ),
          Reporte(
            reporteId: 'r2',
            uid: 'user-1',
            correoAutor: 'user1@example.com',
            tipoDano: 'Lámpara averiada',
            tipoUbicacion: TipoEspacio.aula,
            edificio: 'Edificio B',
            piso: 'Piso 2',
            espacio: 'Salón 202',
            descripcion: 'Lámpara parpadea',
            estado: EstadoReporte.enProceso,
            tieneFoto: true,
            creadoEn: DateTime(2026, 9, 5),
          ),
        ];

        await tester.pumpWidget(createTestWidget(Stream.value(reportes)));
        await tester.pumpAndSettle();

        // Verificar 2 ReportCard
        expect(find.byType(ReportCard), findsNWidgets(2));

        // Verificar StatusBadge para cada estado - usar toList() para acceder por índice
        final reportCards = tester
            .widgetList<ReportCard>(find.byType(ReportCard))
            .toList();
        expect(reportCards[0].estado, EstadoReporte.pendiente);
        expect(reportCards[1].estado, EstadoReporte.enProceso);

        // Verificar contenido básico
        expect(find.text('Silla dañada'), findsOneWidget);
        expect(find.text('Lámpara averiada'), findsOneWidget);
        expect(find.text('Edificio A · Piso 1 · Salón 101'), findsOneWidget);
        expect(find.text('Edificio B · Piso 2 · Salón 202'), findsOneWidget);
      },
    );

    testWidgets('con lista vacía: muestra mensaje "No tienes reportes aún"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(Stream.value(<Reporte>[])));
      await tester.pumpAndSettle();

      // Verificar mensaje de lista vacía
      expect(find.text('No tienes reportes aún'), findsOneWidget);
      expect(
        find.textContaining('Cuando crees un reporte desde "Reportar daños"'),
        findsOneWidget,
      );
      expect(find.byType(ReportCard), findsNothing);
    });

    testWidgets(
      'filtro de fechas: Hoy oculta reportes antiguos y se puede limpiar',
      (tester) async {
        final reportes = [
          Reporte(
            reporteId: 'r1',
            uid: 'user-1',
            correoAutor: 'user1@example.com',
            tipoDano: 'Silla dañada',
            tipoUbicacion: TipoEspacio.aula,
            edificio: 'Edificio A',
            piso: 'Piso 1',
            espacio: 'Salón 101',
            descripcion: 'Grieta en la silla',
            estado: EstadoReporte.pendiente,
            tieneFoto: false,
            creadoEn: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];

        await tester.pumpWidget(createTestWidget(Stream.value(reportes)));
        await tester.pumpAndSettle();
        expect(find.byType(ReportCard), findsOneWidget);

        await tester.tap(find.widgetWithText(ChoiceChip, 'Hoy'));
        await tester.pumpAndSettle();

        expect(
          find.text('No hay reportes en este rango de fechas'),
          findsOneWidget,
        );
        expect(find.byType(ReportCard), findsNothing);

        await tester.tap(find.text('Ver todo el tiempo'));
        await tester.pumpAndSettle();

        expect(find.byType(ReportCard), findsOneWidget);
        expect(find.text('Silla dañada'), findsOneWidget);
      },
    );

    testWidgets('en estado loading: muestra CircularProgressIndicator', (
      tester,
    ) async {
      // Stream que nunca emite (simula carga)
      final controller = StreamController<List<Reporte>>();
      // No cerramos el controller ni emitimos nada

      await tester.pumpWidget(createTestWidget(controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('en estado de error: muestra el mensaje y Reintentar recarga', (
      tester,
    ) async {
      var llamadas = 0;
      await tester.pumpWidget(
        createTestWidgetWithOverride(
          misReportesProvider.overrideWith((ref) {
            llamadas++;
            if (llamadas == 1) {
              // Simula el PERMISSION_DENIED de Firestore.
              return Stream<List<Reporte>>.error(
                Exception('[cloud_firestore/permission-denied]'),
              );
            }
            return Stream.value(<Reporte>[]);
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudieron cargar tus reportes'), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsOneWidget);

      // El botón recrea el proveedor en lugar de obligar a reiniciar la app.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(llamadas, 2);
      expect(find.text('No tienes reportes aún'), findsOneWidget);
    });
  });
}
