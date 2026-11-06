import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/fallas_app_providers.dart';
import '../domain/falla_app.dart';

/// Fallas de la app reportadas (solo lectura, sin estados).
///
/// El superadministrador puede buscar, filtrar por fecha y revisar los datos
/// técnicos que se capturan automáticamente al reportar.
class FallasAppScreen extends ConsumerStatefulWidget {
  const FallasAppScreen({super.key});

  @override
  ConsumerState<FallasAppScreen> createState() => _FallasAppScreenState();
}

class _FallasAppScreenState extends ConsumerState<FallasAppScreen> {
  final TextEditingController _busqueda = TextEditingController();
  _FiltroFecha _filtro = _FiltroFecha.todas;
  bool _recientesPrimero = true;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_alCambiarBusqueda);
  }

  @override
  void dispose() {
    _busqueda.removeListener(_alCambiarBusqueda);
    _busqueda.dispose();
    super.dispose();
  }

  void _alCambiarBusqueda() => setState(() {});

  Future<void> _recargar() async {
    ref.invalidate(fallasAppListProvider);
    try {
      await ref.read(fallasAppListProvider.future);
    } catch (_) {
      // El estado de error lo muestra el propio provider.
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _busqueda.clear();
      _filtro = _FiltroFecha.todas;
      _recientesPrimero = true;
    });
  }

  List<FallaApp> _filtrar(List<FallaApp> fallas) {
    final String consulta = _busqueda.text.trim().toLowerCase();
    final DateTime ahora = DateTime.now();
    final DateTime inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final DateTime inicioSemana = inicioHoy.subtract(const Duration(days: 6));

    final List<FallaApp> visibles = fallas.where((falla) {
      if (consulta.isNotEmpty) {
        final String texto = <String?>[
          falla.correo,
          falla.mensaje,
          falla.pantalla,
          falla.plataforma,
          falla.sistemaOperativo,
          falla.dispositivo,
          falla.versionApp,
        ].whereType<String>().join(' ').toLowerCase();
        if (!texto.contains(consulta)) return false;
      }

      final DateTime fecha = falla.creadoEn.toDate();
      return switch (_filtro) {
        _FiltroFecha.todas => true,
        _FiltroFecha.hoy => !fecha.isBefore(inicioHoy),
        _FiltroFecha.semana => !fecha.isBefore(inicioSemana),
      };
    }).toList();

    visibles.sort((a, b) {
      final int comparacion = a.creadoEn.compareTo(b.creadoEn);
      return _recientesPrimero ? -comparacion : comparacion;
    });
    return visibles;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FallaApp>> fallasAsync = ref.watch(
      fallasAppListProvider,
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              UtsHeader(
                titulo: 'Fallas de la app',
                subtitulo: 'Reportes enviados por los usuarios',
                mostrarLogo: false,
                accion: IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _recargar,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              Expanded(
                child: fallasAsync.when(
                  loading: () => const _CargandoFallas(),
                  error: (error, _) => _ErrorFallas(
                    mensaje: error.toString(),
                    onReintentar: _recargar,
                  ),
                  data: (fallas) => RefreshIndicator(
                    color: AppColors.welcomeBackground,
                    onRefresh: _recargar,
                    child: _ListaFallas(
                      fallas: fallas,
                      visibles: _filtrar(fallas),
                      busqueda: _busqueda,
                      filtro: _filtro,
                      recientesPrimero: _recientesPrimero,
                      onFiltro: (filtro) => setState(() => _filtro = filtro),
                      onOrdenar: () => setState(
                        () => _recientesPrimero = !_recientesPrimero,
                      ),
                      onLimpiar: _limpiarFiltros,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaFallas extends StatelessWidget {
  const _ListaFallas({
    required this.fallas,
    required this.visibles,
    required this.busqueda,
    required this.filtro,
    required this.recientesPrimero,
    required this.onFiltro,
    required this.onOrdenar,
    required this.onLimpiar,
  });

  final List<FallaApp> fallas;
  final List<FallaApp> visibles;
  final TextEditingController busqueda;
  final _FiltroFecha filtro;
  final bool recientesPrimero;
  final ValueChanged<_FiltroFecha> onFiltro;
  final VoidCallback onOrdenar;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final DateTime ahora = DateTime.now();
    final int hoy = fallas
        .where((f) => _esMismoDia(f.creadoEn.toDate(), ahora))
        .length;
    final DateTime inicioSemana = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    ).subtract(const Duration(days: 6));
    final int semana = fallas
        .where((f) => !f.creadoEn.toDate().isBefore(inicioSemana))
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _ResumenFallas(total: fallas.length, hoy: hoy, semana: semana),
        const SizedBox(height: 18),
        PillField(
          hint: 'Buscar por correo, mensaje o pantalla',
          icono: Icons.search_rounded,
          controlador: busqueda,
          borde: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final opcion in _FiltroFecha.values) ...[
                      _ChipFiltro(
                        texto: opcion.etiqueta,
                        activo: opcion == filtro,
                        onTap: () => onFiltro(opcion),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            _BotonOrden(recientesPrimero: recientesPrimero, onTap: onOrdenar),
          ],
        ),
        const SizedBox(height: 16),
        if (fallas.isEmpty)
          _SinFallas(onReportar: () => context.push(AppRoutes.reportarFalla))
        else if (visibles.isEmpty)
          _SinResultados(onLimpiar: onLimpiar)
        else
          for (final falla in visibles) ...[
            _FallaCard(falla: falla),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _ResumenFallas extends StatelessWidget {
  const _ResumenFallas({
    required this.total,
    required this.hoy,
    required this.semana,
  });

  final int total;
  final int hoy;
  final int semana;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metrica(
            icono: Icons.bug_report_outlined,
            valor: total,
            etiqueta: total == 1 ? 'falla' : 'fallas',
            destacada: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metrica(
            icono: Icons.today_outlined,
            valor: hoy,
            etiqueta: 'hoy',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metrica(
            icono: Icons.date_range_outlined,
            valor: semana,
            etiqueta: '7 días',
          ),
        ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.destacada = false,
  });

  final IconData icono;
  final int valor;
  final String etiqueta;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final Color fondoIcono = destacada
        ? Color.alphaBlend(
            AppColors.utsGreen.withValues(alpha: 0.28),
            Colors.white,
          )
        : AppColors.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: fondoIcono,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 19, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valor',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(texto),
      selected: activo,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.utsGreen,
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: activo ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BotonOrden extends StatelessWidget {
  const _BotonOrden({required this.recientesPrimero, required this.onTap});

  final bool recientesPrimero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_vert_rounded, size: 18),
              const SizedBox(width: 4),
              Text(
                recientesPrimero ? 'Recientes' : 'Antiguas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallaCard extends StatefulWidget {
  const _FallaCard({required this.falla});

  final FallaApp falla;

  @override
  State<_FallaCard> createState() => _FallaCardState();
}

class _FallaCardState extends State<_FallaCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final FallaApp falla = widget.falla;
    final DateTime fecha = falla.creadoEn.toDate();
    final bool esNueva =
        !fecha.isBefore(DateTime.now().subtract(const Duration(hours: 24))) &&
        !fecha.isAfter(DateTime.now());
    final bool mensajeLargo =
        falla.mensaje.length > 150 || '\n'.allMatches(falla.mensaje).length > 2;
    final String titulo = (falla.pantalla ?? '').trim().isEmpty
        ? 'Falla reportada'
        : 'Pantalla: ${falla.pantalla}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: esNueva ? AppColors.utsGreen : AppColors.divider,
            width: 5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      AppColors.utsGreen.withValues(alpha: 0.24),
                      Colors.white,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bug_report_outlined,
                    size: 22,
                    color: AppColors.welcomeBackground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              falla.correo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (esNueva) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        AppColors.utsGreen.withValues(alpha: 0.35),
                        Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Nueva',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                falla.mensaje,
                maxLines: _expandido ? null : 3,
                overflow: _expandido
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                ),
              ),
            ),
            if (mensajeLargo)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkWell(
                  onTap: () => setState(() => _expandido = !_expandido),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _expandido ? 'Ver menos' : 'Ver más',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.welcomeBackground,
                      ),
                    ),
                  ),
                ),
              ),
            if (_hayDatosTecnicos(falla)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if ((falla.dispositivo ?? '').isNotEmpty)
                    _DatoChip(
                      icono: Icons.smartphone_rounded,
                      texto: falla.dispositivo!,
                    ),
                  if ((falla.sistemaOperativo ?? '').isNotEmpty)
                    _DatoChip(
                      icono: Icons.memory_rounded,
                      texto: falla.sistemaOperativo!,
                    ),
                  if ((falla.versionApp ?? '').isNotEmpty)
                    _DatoChip(
                      icono: Icons.verified_outlined,
                      texto: 'v${falla.versionApp}',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _fechaRelativa(fecha),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _BotonCopiar(
                  tooltip: 'Copiar correo',
                  icono: Icons.alternate_email_rounded,
                  texto: falla.correo,
                  mensaje: 'Correo copiado',
                ),
                _BotonCopiar(
                  tooltip: 'Copiar mensaje',
                  icono: Icons.copy_rounded,
                  texto: falla.mensaje,
                  mensaje: 'Mensaje copiado',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hayDatosTecnicos(FallaApp falla) {
    return (falla.dispositivo ?? '').isNotEmpty ||
        (falla.sistemaOperativo ?? '').isNotEmpty ||
        (falla.versionApp ?? '').isNotEmpty;
  }
}

class _DatoChip extends StatelessWidget {
  const _DatoChip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonCopiar extends StatelessWidget {
  const _BotonCopiar({
    required this.tooltip,
    required this.icono,
    required this.texto,
    required this.mensaje,
  });

  final String tooltip;
  final IconData icono;
  final String texto;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: texto));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: Icon(icono, size: 18),
      color: AppColors.textSecondary,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
    );
  }
}

class _SinFallas extends StatelessWidget {
  const _SinFallas({required this.onReportar});

  final VoidCallback onReportar;

  @override
  Widget build(BuildContext context) {
    return _TarjetaEstado(
      icono: Icons.check_circle_outline_rounded,
      titulo: 'Todo tranquilo por aquí',
      mensaje: 'Cuando alguien reporte una falla, aparecerá en esta lista.',
      accion: PrimaryButton(texto: 'REPORTAR UNA FALLA', onPressed: onReportar),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.onLimpiar});

  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    return _TarjetaEstado(
      icono: Icons.search_off_rounded,
      titulo: 'Sin coincidencias',
      mensaje: 'Prueba con otra búsqueda o cambia el filtro de fecha.',
      accion: TextButton(
        onPressed: onLimpiar,
        child: const Text('Limpiar filtros'),
      ),
    );
  }
}

class _TarjetaEstado extends StatelessWidget {
  const _TarjetaEstado({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                AppColors.utsGreen.withValues(alpha: 0.22),
                Colors.white,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 34, color: AppColors.welcomeBackground),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (accion != null) ...[
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: accion),
          ],
        ],
      ),
    );
  }
}

class _CargandoFallas extends StatefulWidget {
  const _CargandoFallas();

  @override
  State<_CargandoFallas> createState() => _CargandoFallasState();
}

class _CargandoFallasState extends State<_CargandoFallas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: const [
          _SkeletonMetricas(),
          SizedBox(height: 18),
          _SkeletonTarjeta(),
          SizedBox(height: 14),
          _SkeletonTarjeta(),
          SizedBox(height: 14),
          _SkeletonTarjeta(),
        ],
      ),
    );
  }
}

class _SkeletonMetricas extends StatelessWidget {
  const _SkeletonMetricas();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonTarjeta extends StatelessWidget {
  const _SkeletonTarjeta();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorFallas extends StatelessWidget {
  const _ErrorFallas({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _TarjetaEstado(
          icono: Icons.cloud_off_rounded,
          titulo: 'No pudimos cargar las fallas',
          mensaje: 'Revisa tu conexión e inténtalo de nuevo.',
          accion: PrimaryButton(texto: 'REINTENTAR', onPressed: onReintentar),
        ),
      ],
    );
  }
}

enum _FiltroFecha {
  todas('Todas'),
  hoy('Hoy'),
  semana('7 días');

  const _FiltroFecha(this.etiqueta);

  final String etiqueta;
}

bool _esMismoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _fechaRelativa(DateTime fecha) {
  final Duration diferencia = DateTime.now().difference(fecha);
  if (diferencia.isNegative || diferencia.inMinutes < 1) return 'ahora';
  if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
  if (diferencia.inDays == 1) return 'ayer';
  if (diferencia.inDays < 7) return 'hace ${diferencia.inDays} días';
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
