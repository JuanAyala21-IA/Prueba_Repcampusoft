import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/features/admin/presentation/assigned_reports_screen.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/reportes/data/providers/reporte_providers.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/shared/widgets/report_card.dart';

void main() {
  Reporte reporte({
    required String id,
    required String tipo,
    required EstadoReporte estado,
    String? asignadoA,
    String? asignadoNombre,
  }) {
    return Reporte(
      reporteId: id,
      uid: 'autor-uid',
      correoAutor: 'autor@uts.edu.co',
      tipoDano: tipo,
      tipoUbicacion: TipoEspacio.aula,
      edificio: 'Edificio A',
      piso: 'Piso 1',
      espacio: 'Salón 101',
      descripcion: 'Descripción',
      estado: estado,
      tieneFoto: false,
      creadoEn: DateTime(2026, 9, 8, 10, 30),
      asignadoA: asignadoA,
      asignadoNombre: asignadoNombre,
      asignadoEn: asignadoA == null ? null : DateTime(2026, 9, 9, 8),
    );
  }

  Widget crearApp(List<Reporte> reportes) {
    return ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          () => _SesionMantenimientoFake(uid: 'mant-1'),
        ),
        todosLosReportesProvider.overrideWith(
          (ref, filtros) => Stream.value(reportes),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.misReportesAsignados,
          routes: [
            GoRoute(
              path: AppRoutes.misReportesAsignados,
              builder: (_, _) => const AssignedReportsScreen(),
            ),
            GoRoute(
              path: AppRoutes.gestionReporte,
              builder: (_, _) => const Scaffold(body: Text('GESTIONAR')),
            ),
            GoRoute(
              path: AppRoutes.danosReportados,
              builder: (_, _) => const Scaffold(body: Text('DANOS')),
            ),
          ],
        ),
      ),
    );
  }

  group('AssignedReportsScreen (mantenimiento)', () {
    testWidgets('solo muestra los reportes activos asignados al encargado', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearApp([
          reporte(
            id: 'mio',
            tipo: 'Reporte mío',
            estado: EstadoReporte.pendiente,
            asignadoA: 'mant-1',
            asignadoNombre: 'Marta',
          ),
          reporte(
            id: 'mio-solucionado',
            tipo: 'Reporte mío solucionado',
            estado: EstadoReporte.solucionado,
            asignadoA: 'mant-1',
            asignadoNombre: 'Marta',
          ),
          reporte(
            id: 'ajeno',
            tipo: 'Reporte ajeno',
            estado: EstadoReporte.pendiente,
            asignadoA: 'mant-2',
            asignadoNombre: 'Pedro',
          ),
          reporte(
            id: 'libre',
            tipo: 'Reporte libre',
            estado: EstadoReporte.pendiente,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reporte mío'), findsOneWidget);
      expect(find.text('Reporte mío solucionado'), findsNothing);
      expect(find.text('Reporte ajeno'), findsNothing);
      expect(find.text('Reporte libre'), findsNothing);
      expect(find.text('1 reporte por resolver'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío y permite ir a daños reportados', (
      tester,
    ) async {
      await tester.pumpWidget(crearApp([]));
      await tester.pumpAndSettle();

      expect(find.text('No tienes reportes asignados'), findsOneWidget);
      await tester.tap(find.text('Ver daños reportados'));
      await tester.pumpAndSettle();
      expect(find.text('DANOS'), findsOneWidget);
    });

    testWidgets('tocar una tarjeta abre la gestión del reporte', (
      tester,
    ) async {
      await tester.pumpWidget(
        crearApp([
          reporte(
            id: 'mio',
            tipo: 'Reporte mío',
            estado: EstadoReporte.enProceso,
            asignadoA: 'mant-1',
            asignadoNombre: 'Marta',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ReportCard));
      await tester.pumpAndSettle();
      expect(find.text('GESTIONAR'), findsOneWidget);
    });
  });
}

class _SesionMantenimientoFake extends SesionController {
  _SesionMantenimientoFake({required this.uid});

  final String uid;

  @override
  Sesion build() => Sesion.rolAplicado(
    uid: uid,
    correo: '$uid@uts.edu.co',
    rol: RolEnum.mantenimiento,
  );
}
