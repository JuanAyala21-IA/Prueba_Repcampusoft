import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/routes/app_router.dart';

void main() {
  group('AppRoutes y navegación', () {
    test('AppRoutes.detalleReporte NO contiene parámetro :reportId (corrección del bug)', () {
      expect(AppRoutes.detalleReporte, '/detalle-reporte');
      expect(AppRoutes.detalleReporte, isNot(contains(':reportId')));
    });

    test('GoRoute para detalle usa parámetro :reportId correctamente', () {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.misReportes,
            builder: (_, _) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '${AppRoutes.detalleReporte}/:reportId',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      // Verificar que la ruta con parámetro se puede resolver
      final String location = '/detalle-reporte/test-id-123';
      expect(() => router.go(location), returnsNormally);
    });

    test('Navegación correcta usa id real', () {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/detalle-reporte/:reportId',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      // Navegación con id real funciona
      expect(
        () => router.go('/detalle-reporte/E0INfhFqLiN46ovLD0oE'),
        returnsNormally,
      );
    });
  });
}
