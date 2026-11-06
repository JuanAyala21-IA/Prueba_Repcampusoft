import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/reportes/data/providers/reporte_providers.dart';
import 'package:repcampusoft/features/reportes/domain/historial_entry.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/features/admin/presentation/manage_report_screen.dart';
import 'package:repcampusoft/shared/widgets/primary_button.dart';

void main() {
  group('ManageReportScreen widget tests', () {
    Widget createTestWidget({
      required Stream<Reporte?> reporteStream,
      required Stream<List<HistorialEntry>> historialStream,
      RolEnum rol = RolEnum.administrativo,
      String uid = 'admin-uid',
    }) {
      return ProviderScope(
        overrides: [
          sesionProvider.overrideWith(() => _SesionFake(rol: rol, uid: uid)),
          reporteByIdProvider.overrideWith((ref, reportId) => reporteStream),
          historialProvider.overrideWith((ref, reportId) => historialStream),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/gestion-reporte?reportId=test-report-id',
            routes: [
              GoRoute(
                path: AppRoutes.danosReportados,
                builder: (_, _) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRoutes.gestionReporte,
                builder: (_, _) => const ManageReportScreen(),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets(
      'estado Pendiente: muestra solo botones En revision y Rechazado (transiciones permitidas)',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.pendiente,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar que NO aparecen botones para estados finales o intermedios no permitidos
        expect(find.textContaining('Solucionado'), findsNothing);
        expect(find.textContaining('En proceso'), findsNothing);

        // Verificar que SÍ aparecen los botones permitidos desde Pendiente
        expect(
          find.textContaining('En revisi'),
          findsOneWidget,
        ); // "En revisión"
        expect(find.textContaining('Rechazado'), findsOneWidget);
      },
    );

    testWidgets('mantenimiento: no ofrece Rechazado en los cambios de estado', (
      tester,
    ) async {
      final reporte = Reporte(
        reporteId: 'test-report-id',
        uid: 'autor-uid',
        correoAutor: 'autor@example.com',
        tipoDano: 'Silla dañada',
        tipoUbicacion: TipoEspacio.aula,
        edificio: 'Edificio A',
        piso: 'Piso 4',
        espacio: 'Salón 402 A',
        descripcion: 'Silla con tornillos sueltos',
        estado: EstadoReporte.pendiente,
        tieneFoto: false,
        creadoEn: DateTime(2026, 9, 8, 10, 30),
        asignadoA: 'mant-uid',
        asignadoNombre: 'Encargado Mantenimiento',
      );

      await tester.pumpWidget(
        createTestWidget(
          reporteStream: Stream.value(reporte),
          historialStream: Stream.value(<HistorialEntry>[]),
          rol: RolEnum.mantenimiento,
          uid: 'mant-uid',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('En revisi'), findsOneWidget);
      expect(find.textContaining('Rechazado'), findsNothing);
    });

    testWidgets(
      'estado En revision: muestra solo botones En proceso y Rechazado',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Lámpara averiada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio B',
          piso: 'Piso 2',
          espacio: 'Salón 202',
          descripcion: 'Lámpara no enciende',
          estado: EstadoReporte.enRevision,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 7, 14, 0),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // No debe aparecer Pendiente ni Solucionado
        expect(find.textContaining('Pendiente'), findsNothing);
        expect(find.textContaining('Solucionado'), findsNothing);

        // Sí debe aparecer En proceso y Rechazado
        expect(find.textContaining('En proceso'), findsOneWidget);
        expect(find.textContaining('Rechazado'), findsOneWidget);
      },
    );

    testWidgets(
      'estado En proceso: muestra solo botones Solucionado y Rechazado',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Puerta dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio B',
          piso: 'Piso 1',
          espacio: 'Salón 105',
          descripcion: 'Puerta no cierra',
          estado: EstadoReporte.enProceso,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 5, 9, 0),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // No debe aparecer Pendiente ni En revision
        expect(find.textContaining('Pendiente'), findsNothing);
        expect(find.textContaining('En revisi'), findsNothing);

        // Sí debe aparecer Solucionado y Rechazado
        expect(find.textContaining('Solucionado'), findsOneWidget);
        expect(find.textContaining('Rechazado'), findsOneWidget);
      },
    );

    testWidgets(
      'estado Solucionado: NO muestra botones de transición (estado final)',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.solucionado,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // Debe mostrar mensaje de estado final
        expect(find.textContaining('estado final'), findsOneWidget);
        // No debe haber ChoiceChips de transición
        expect(find.byType(ChoiceChip), findsNothing);
      },
    );

    testWidgets(
      'estado Rechazado: NO muestra botones de transición (estado final)',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Reporte falso',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio C',
          piso: 'Piso 1',
          espacio: 'Salón 101',
          descripcion: 'Reporte sin fundamento',
          estado: EstadoReporte.rechazado,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('estado final'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);
      },
    );

    testWidgets(
      'al elegir Rechazado: botón guardar deshabilitado si no hay observación, habilitado al escribirla',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.pendiente,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // Encontrar y tocar el chip "Rechazado"
        final rechazoChip = find.textContaining('Rechazado');
        expect(rechazoChip, findsOneWidget);
        await tester.ensureVisible(rechazoChip);
        await tester.pumpAndSettle();
        await tester.tap(rechazoChip);
        await tester.pumpAndSettle();

        // Verificar que el botón está deshabilitado (onPressed = null porque _requiereObservacion = true)
        final guardarButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(
          guardarButton.onPressed,
          isNull,
          reason: 'Botón debe estar deshabilitado sin observación',
        );

        // Escribir observación
        await tester.enterText(
          find.byType(TextField),
          'Información insuficiente',
        );
        await tester.pumpAndSettle();

        // Verificar que el botón ahora está habilitado
        final guardarButtonHabilitado = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(
          guardarButtonHabilitado.onPressed,
          isNotNull,
          reason: 'Botón debe estar habilitado con observación',
        );
      },
    );

    testWidgets(
      'al elegir transición válida (no Rechazado): botón guardar habilitado sin observación',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.pendiente,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        final historial = <HistorialEntry>[];

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(historial),
          ),
        );
        await tester.pumpAndSettle();

        // Tocar "En revisión" (transición válida no Rechazado)
        final enRevisionChip = find.textContaining('En revisi');
        expect(enRevisionChip, findsOneWidget);
        await tester.ensureVisible(enRevisionChip);
        await tester.pumpAndSettle();
        await tester.tap(enRevisionChip);
        await tester.pumpAndSettle();

        // Botón debe estar habilitado (no requiere observación para En revision)
        final guardarButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(
          guardarButton.onPressed,
          isNotNull,
          reason:
              'Botón debe estar habilitado para En revisión sin observación',
        );
      },
    );

    testWidgets('reporte no existe (null): muestra mensaje y botón volver', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          reporteStream: Stream.value(null),
          historialStream: Stream.value(<HistorialEntry>[]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('El reporte no existe'), findsOneWidget);
      expect(find.text('Volver a daños reportados'), findsOneWidget);
    });

    testWidgets('en estado loading: muestra CircularProgressIndicator', (
      tester,
    ) async {
      final controller = StreamController<Reporte?>();
      // No emitir nada

      await tester.pumpWidget(
        createTestWidget(
          reporteStream: controller.stream,
          historialStream: Stream.value(<HistorialEntry>[]),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });
    testWidgets(
      'al elegir Solucionado: muestra el selector de evidencia de la solución',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.enProceso,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(<HistorialEntry>[]),
          ),
        );
        await tester.pumpAndSettle();

        final solucionadoChip = find.textContaining('Solucionado');
        expect(solucionadoChip, findsOneWidget);
        await tester.ensureVisible(solucionadoChip);
        await tester.pumpAndSettle();
        await tester.tap(solucionadoChip);
        await tester.pumpAndSettle();

        expect(find.text('Evidencia de la solución'), findsOneWidget);
        expect(find.text('Adjuntar imagen'), findsOneWidget);
        expect(
          find.textContaining('Debes adjuntar la foto de evidencia'),
          findsOneWidget,
        );
        final guardarButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(
          guardarButton.onPressed,
          isNull,
          reason: 'Sin evidencia no se puede guardar Solucionado',
        );
      },
    );

    testWidgets(
      'mantenimiento sin asignar: muestra el botón Tomar reporte y no los chips',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.pendiente,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
        );

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(<HistorialEntry>[]),
            rol: RolEnum.mantenimiento,
            uid: 'mant-1',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tomar reporte'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);
        expect(find.text('Sin asignar'), findsOneWidget);
      },
    );

    testWidgets(
      'mantenimiento: un reporte tomado por otro compañero es de solo lectura',
      (tester) async {
        final reporte = Reporte(
          reporteId: 'test-report-id',
          uid: 'autor-uid',
          correoAutor: 'autor@example.com',
          tipoDano: 'Silla dañada',
          tipoUbicacion: TipoEspacio.aula,
          edificio: 'Edificio A',
          piso: 'Piso 4',
          espacio: 'Salón 402 A',
          descripcion: 'Silla con tornillos sueltos',
          estado: EstadoReporte.pendiente,
          tieneFoto: false,
          creadoEn: DateTime(2026, 9, 8, 10, 30),
          asignadoA: 'mant-2',
          asignadoNombre: 'Pedro Pérez',
        );

        await tester.pumpWidget(
          createTestWidget(
            reporteStream: Stream.value(reporte),
            historialStream: Stream.value(<HistorialEntry>[]),
            rol: RolEnum.mantenimiento,
            uid: 'mant-1',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('ya fue tomado por Pedro Pérez'),
          findsOneWidget,
        );
        expect(find.text('Tomar reporte'), findsNothing);
        expect(find.byType(ChoiceChip), findsNothing);
      },
    );

    testWidgets('mantenimiento asignado: puede cambiar el estado del reporte', (
      tester,
    ) async {
      final reporte = Reporte(
        reporteId: 'test-report-id',
        uid: 'autor-uid',
        correoAutor: 'autor@example.com',
        tipoDano: 'Silla dañada',
        tipoUbicacion: TipoEspacio.aula,
        edificio: 'Edificio A',
        piso: 'Piso 4',
        espacio: 'Salón 402 A',
        descripcion: 'Silla con tornillos sueltos',
        estado: EstadoReporte.pendiente,
        tieneFoto: false,
        creadoEn: DateTime(2026, 9, 8, 10, 30),
        asignadoA: 'mant-1',
        asignadoNombre: 'Marta',
      );

      await tester.pumpWidget(
        createTestWidget(
          reporteStream: Stream.value(reporte),
          historialStream: Stream.value(<HistorialEntry>[]),
          rol: RolEnum.mantenimiento,
          uid: 'mant-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.text('Tomar reporte'), findsNothing);
      expect(find.text('Marta'), findsOneWidget);
    });
  });
}

class _SesionFake extends SesionController {
  _SesionFake({required this.rol, required this.uid});

  final RolEnum rol;
  final String uid;

  @override
  Sesion build() =>
      Sesion.rolAplicado(uid: uid, correo: '$uid@uts.edu.co', rol: rol);
}
