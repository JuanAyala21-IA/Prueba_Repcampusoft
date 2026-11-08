import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/estado_reporte_style.dart';
import '../../../../core/utils/rango_fechas.dart';
import '../../domain/estadisticas_reportes.dart';

/// Dashboard de estadísticas que se muestra dentro de "Daños Reportados".
class ReportesEstadisticasPanel extends StatelessWidget {
  const ReportesEstadisticasPanel({
    super.key,
    required this.periodo,
    required this.general,
    required this.rango,
  });

  final EstadisticasReportes periodo;
  final EstadisticasReportes general;
  final RangoFechas rango;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TarjetaGeneral(general: general),
          const SizedBox(height: 14),
          _TarjetaPeriodo(periodo: periodo, rango: rango),
          const SizedBox(height: 14),
          _TarjetaEstados(estadisticas: periodo),
          const SizedBox(height: 14),
          _TarjetaTendencia(estadisticas: periodo),
          const SizedBox(height: 14),
          _TarjetaDetalle(estadisticas: periodo),
        ],
      ),
    );
  }
}

class _TarjetaGeneral extends StatelessWidget {
  const _TarjetaGeneral({required this.general});

  final EstadisticasReportes general;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      titulo: 'General histórico',
      subtitulo: 'Todos los reportes registrados',
      icono: Icons.insights_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DatoGrande(
                  valor: '${general.total}',
                  etiqueta: 'Reportes totales',
                ),
              ),
              Expanded(
                child: _DatoGrande(
                  valor: '${general.solucionados}',
                  etiqueta: 'Solucionados',
                  color: AppColors.estadoSolucionado,
                ),
              ),
              Expanded(
                child: _DatoGrande(
                  valor: '${general.sinCerrar}',
                  etiqueta: 'Sin cerrar',
                  color: AppColors.estadoPendiente,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: general.total == 0
                  ? 0
                  : general.solucionados / general.total,
              minHeight: 10,
              color: AppColors.estadoSolucionado,
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${general.porcentajeSolucionados.toStringAsFixed(1)} % de '
              'los reportes están solucionados',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPeriodo extends StatelessWidget {
  const _TarjetaPeriodo({required this.periodo, required this.rango});

  final EstadisticasReportes periodo;
  final RangoFechas rango;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      titulo: 'Periodo seleccionado',
      subtitulo: '${rango.descripcion} · por fecha de creación del reporte',
      icono: Icons.date_range_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DatoGrande(
                  valor: '${periodo.total}',
                  etiqueta: 'Reportes',
                ),
              ),
              Expanded(
                child: _DatoGrande(
                  valor:
                      '${periodo.porcentajeSolucionados.toStringAsFixed(1)} %',
                  etiqueta: 'Resueltos',
                  color: AppColors.estadoSolucionado,
                ),
              ),
              Expanded(
                child: _DatoGrande(
                  valor: periodo.promedioDiasSolucion == 0
                      ? '—'
                      : '${periodo.promedioDiasSolucion.toStringAsFixed(1)} d',
                  etiqueta: 'Prom. solución',
                ),
              ),
            ],
          ),
          if (periodo.total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: periodo.total == 0
                    ? 0
                    : periodo.solucionados / periodo.total,
                minHeight: 10,
                color: AppColors.estadoSolucionado,
                backgroundColor: AppColors.surface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaEstados extends StatelessWidget {
  const _TarjetaEstados({required this.estadisticas});

  final EstadisticasReportes estadisticas;

  @override
  Widget build(BuildContext context) {
    if (estadisticas.total == 0) {
      return const _Tarjeta(
        titulo: 'Estados',
        subtitulo: 'No hay reportes en este rango de fechas',
        icono: Icons.pie_chart_outline,
        child: SizedBox.shrink(),
      );
    }

    return _Tarjeta(
      titulo: 'Distribución por estado',
      subtitulo: 'Reportes del periodo según su estado actual',
      icono: Icons.pie_chart_outline,
      child: Column(
        children: [
          for (final EstadoReporte estado in EstadoReporte.values)
            _FilaEstado(
              estado: estado,
              cantidad: estadisticas.porEstado[estado] ?? 0,
              total: estadisticas.total,
            ),
        ],
      ),
    );
  }
}

class _FilaEstado extends StatelessWidget {
  const _FilaEstado({
    required this.estado,
    required this.cantidad,
    required this.total,
  });

  final EstadoReporte estado;
  final int cantidad;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double fraccion = total == 0 ? 0 : cantidad / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              estado.nombre,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: fraccion,
                minHeight: 12,
                color: estado.color,
                backgroundColor: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.right,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTendencia extends StatelessWidget {
  const _TarjetaTendencia({required this.estadisticas});

  final EstadisticasReportes estadisticas;

  @override
  Widget build(BuildContext context) {
    if (estadisticas.porFecha.isEmpty) {
      return const SizedBox.shrink();
    }
    final int maximo = estadisticas.porFecha.fold<int>(
      0,
      (int max, EstadisticaPorFecha item) =>
          item.total > max ? item.total : max,
    );

    return _Tarjeta(
      titulo: estadisticas.agrupadoPorMes
          ? 'Reportes por mes'
          : 'Reportes por día',
      subtitulo: 'Cantidad de reportes creados en cada fecha',
      icono: Icons.bar_chart_outlined,
      child: SizedBox(
        height: 180,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final EstadisticaPorFecha item in estadisticas.porFecha)
                _Barra(
                  etiqueta: item.etiqueta,
                  valor: item.total,
                  maximo: maximo,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
  });

  final String etiqueta;
  final int valor;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final double altura = maximo == 0 ? 4 : (valor / maximo) * 100;
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (valor > 0)
            Text(
              '$valor',
              style: const TextStyle(fontSize: 9, color: AppColors.textPrimary),
            ),
          const SizedBox(height: 2),
          Container(
            height: altura < 4 ? 4 : altura,
            width: 18,
            decoration: BoxDecoration(
              color: valor == 0 ? AppColors.surface : AppColors.utsGreen,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _TarjetaDetalle extends StatelessWidget {
  const _TarjetaDetalle({required this.estadisticas});

  final EstadisticasReportes estadisticas;

  @override
  Widget build(BuildContext context) {
    if (estadisticas.total == 0) return const SizedBox.shrink();
    return _Tarjeta(
      titulo: 'Detalle por fecha',
      subtitulo: 'Totales exactos del periodo',
      icono: Icons.table_chart_outlined,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            'Ver ${estadisticas.porFecha.length} fechas',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            for (final EstadisticaPorFecha item in estadisticas.porFecha)
              if (item.total > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          item.etiquetaCompleta,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item.total} total · '
                          '${item.cantidad(EstadoReporte.solucionado)} sol. · '
                          '${item.cantidad(EstadoReporte.enProceso)} proc. · '
                          '${item.cantidad(EstadoReporte.rechazado)} rech.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.child,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.sombraTarjeta(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DatoGrande extends StatelessWidget {
  const _DatoGrande({
    required this.valor,
    required this.etiqueta,
    this.color = AppColors.textPrimary,
  });

  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 22,
          ),
        ),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
