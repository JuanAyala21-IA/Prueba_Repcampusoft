import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/result.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/catalogo_providers.dart';
import '../domain/catalogos.dart';

/// Administración de catálogos de reportes.
///
/// Solo se muestra a mantenimiento y superadministrador. Los cambios se
/// guardan en Firestore y aparecen de inmediato en el formulario de los
/// estudiantes.
class CatalogosScreen extends ConsumerStatefulWidget {
  const CatalogosScreen({super.key});

  @override
  ConsumerState<CatalogosScreen> createState() => _CatalogosScreenState();
}

class _CatalogosScreenState extends ConsumerState<CatalogosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    Future<void>.microtask(_sembrarSiHaceFalta);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _sembrarSiHaceFalta() async {
    final Result<void> resultado = await ref
        .read(catalogoRepositoryProvider)
        .sembrarIniciales();
    if (!mounted) return;
    if (resultado is Failure<void>) {
      _mensaje(resultado.message);
    }
    _invalidar();
  }

  void _invalidar() {
    ref.invalidate(edificiosCatalogoProvider);
    ref.invalidate(sitiosCatalogoProvider);
    ref.invalidate(tiposDanoCatalogoProvider);
    ref.invalidate(zonasCatalogoProvider);
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Catálogos de reportes',
                subtitulo: 'Edificios, sitios, daños y zonas',
                mostrarLogo: false,
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                labelColor: AppColors.textPrimary,
                indicatorColor: AppColors.utsGreen,
                tabs: const [
                  Tab(text: 'Edificios'),
                  Tab(text: 'Sitios'),
                  Tab(text: 'Daños'),
                  Tab(text: 'Zonas'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _EdificiosTab(onMensaje: _mensaje),
                    _SitiosTab(onMensaje: _mensaje),
                    _DanosTab(onMensaje: _mensaje),
                    _ZonasTab(onMensaje: _mensaje),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdificiosTab extends ConsumerWidget {
  const _EdificiosTab({required this.onMensaje});

  final void Function(String) onMensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<EdificioCatalogo> items =
        ref.watch(edificiosCatalogoProvider).value ?? <EdificioCatalogo>[];
    return _CatalogoTab(
      titulo: 'Edificios',
      descripcion:
          'Cada edificio define los pisos que aparecen en el formulario.',
      textoAgregar: 'Agregar edificio',
      onAgregar: () => _abrirEdificio(context, ref, items, null),
      onRecargar: () => ref.invalidate(edificiosCatalogoProvider),
      items: items
          .map(
            (EdificioCatalogo item) => _CatalogoCard(
              titulo: item.nombre,
              detalle: item.pisos.join(' · '),
              activo: item.activo,
              onEditar: () => _abrirEdificio(context, ref, items, item),
              onActivo: (bool activo) {
                _guardar(
                  ref,
                  () => ref
                      .read(catalogoRepositoryProvider)
                      .guardarEdificio(item.copyWith(activo: activo)),
                  onMensaje,
                );
              },
              onEliminar: () => _confirmarEliminar(
                context,
                ref,
                item.nombre,
                () => ref
                    .read(catalogoRepositoryProvider)
                    .eliminarEdificio(item.id),
                onMensaje,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SitiosTab extends ConsumerWidget {
  const _SitiosTab({required this.onMensaje});

  final void Function(String) onMensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SitioReporteCatalogo> items =
        ref.watch(sitiosCatalogoProvider).value ?? <SitioReporteCatalogo>[];
    return _CatalogoTab(
      titulo: 'Sitios / tipos de espacio',
      descripcion:
          'Definen qué campos pide el formulario: edificio, piso y referencia.',
      textoAgregar: 'Agregar sitio',
      onAgregar: () => _abrirSitio(context, ref, items, null),
      onRecargar: () => ref.invalidate(sitiosCatalogoProvider),
      items: items
          .map(
            (SitioReporteCatalogo item) => _CatalogoCard(
              titulo: item.nombre,
              detalle: _detalleSitio(item),
              activo: item.activo,
              onEditar: () => _abrirSitio(context, ref, items, item),
              onActivo: (bool activo) {
                _guardar(
                  ref,
                  () => ref
                      .read(catalogoRepositoryProvider)
                      .guardarSitio(item.copyWith(activo: activo)),
                  onMensaje,
                );
              },
              onEliminar: () => _confirmarEliminar(
                context,
                ref,
                item.nombre,
                () =>
                    ref.read(catalogoRepositoryProvider).eliminarSitio(item.id),
                onMensaje,
              ),
            ),
          )
          .toList(),
    );
  }

  String _detalleSitio(SitioReporteCatalogo item) {
    final List<String> partes = <String>[];
    if (item.requiereEdificio) partes.add('edificio');
    if (item.requierePiso) partes.add('piso');
    if (item.muestraReferencia) {
      partes.add(
        item.referenciaObligatoria ? 'referencia obligatoria' : 'referencia',
      );
    }
    if (partes.isEmpty) return 'Sin campos adicionales';
    return 'Pide ${partes.join(', ')}';
  }
}

class _DanosTab extends ConsumerWidget {
  const _DanosTab({required this.onMensaje});

  final void Function(String) onMensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TipoDanoCatalogo> items =
        ref.watch(tiposDanoCatalogoProvider).value ?? <TipoDanoCatalogo>[];
    final List<SitioReporteCatalogo> sitios =
        ref.watch(sitiosCatalogoProvider).value ?? sitiosPorDefecto();
    return _CatalogoTab(
      titulo: 'Tipos de daño',
      descripcion: 'Cada daño se muestra solo en los sitios que le asignes.',
      textoAgregar: 'Agregar tipo de daño',
      onAgregar: () => _abrirTipoDano(context, ref, items, sitios, null),
      onRecargar: () => ref.invalidate(tiposDanoCatalogoProvider),
      items: items
          .map(
            (TipoDanoCatalogo item) => _CatalogoCard(
              titulo: item.nombre,
              detalle: _detalleSitios(item, sitios),
              activo: item.activo,
              onEditar: () => _abrirTipoDano(context, ref, items, sitios, item),
              onActivo: (bool activo) {
                _guardar(
                  ref,
                  () => ref
                      .read(catalogoRepositoryProvider)
                      .guardarTipoDano(item.copyWith(activo: activo)),
                  onMensaje,
                );
              },
              onEliminar: () => _confirmarEliminar(
                context,
                ref,
                item.nombre,
                () => ref
                    .read(catalogoRepositoryProvider)
                    .eliminarTipoDano(item.id),
                onMensaje,
              ),
            ),
          )
          .toList(),
    );
  }

  String _detalleSitios(
    TipoDanoCatalogo item,
    List<SitioReporteCatalogo> sitios,
  ) {
    if (item.sitios.isEmpty) return 'Todos los sitios';
    final List<String> nombres = sitios
        .where((SitioReporteCatalogo s) => item.sitios.contains(s.id))
        .map((SitioReporteCatalogo s) => s.nombre)
        .toList();
    return nombres.isEmpty ? 'Sin sitios asignados' : nombres.join(', ');
  }
}

class _ZonasTab extends ConsumerWidget {
  const _ZonasTab({required this.onMensaje});

  final void Function(String) onMensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ZonaExteriorCatalogo> items =
        ref.watch(zonasCatalogoProvider).value ?? <ZonaExteriorCatalogo>[];
    return _CatalogoTab(
      titulo: 'Zonas exteriores',
      descripcion: 'Opciones que aparecen al elegir una zona exterior.',
      textoAgregar: 'Agregar zona',
      onAgregar: () => _abrirNombre(
        context,
        ref,
        items.map((ZonaExteriorCatalogo e) => e.nombre).toList(),
        nombreInicial: null,
        onGuardar: (String nombre) => ref
            .read(catalogoRepositoryProvider)
            .guardarZona(
              ZonaExteriorCatalogo(
                id: _idUnico(
                  slugCatalogo(nombre),
                  items.map((ZonaExteriorCatalogo e) => e.id).toSet(),
                ),
                nombre: nombre,
                orden: items.length,
              ),
            ),
        onMensaje: onMensaje,
      ),
      onRecargar: () => ref.invalidate(zonasCatalogoProvider),
      items: items
          .map(
            (ZonaExteriorCatalogo item) => _CatalogoCard(
              titulo: item.nombre,
              detalle: 'Zona exterior',
              activo: item.activo,
              onEditar: () => _abrirNombre(
                context,
                ref,
                items.map((ZonaExteriorCatalogo e) => e.nombre).toList(),
                nombreInicial: item.nombre,
                onGuardar: (String nombre) => ref
                    .read(catalogoRepositoryProvider)
                    .guardarZona(item.copyWith(nombre: nombre)),
                onMensaje: onMensaje,
              ),
              onActivo: (bool activo) {
                _guardar(
                  ref,
                  () => ref
                      .read(catalogoRepositoryProvider)
                      .guardarZona(item.copyWith(activo: activo)),
                  onMensaje,
                );
              },
              onEliminar: () => _confirmarEliminar(
                context,
                ref,
                item.nombre,
                () =>
                    ref.read(catalogoRepositoryProvider).eliminarZona(item.id),
                onMensaje,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CatalogoTab extends StatelessWidget {
  const _CatalogoTab({
    required this.titulo,
    required this.descripcion,
    required this.textoAgregar,
    required this.onAgregar,
    required this.onRecargar,
    required this.items,
  });

  final String titulo;
  final String descripcion;
  final String textoAgregar;
  final VoidCallback onAgregar;
  final VoidCallback onRecargar;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add),
            label: Text(textoAgregar),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 54,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                const Text('Todavía no hay elementos.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRecargar,
                  child: const Text('Recargar'),
                ),
              ],
            )
          else
            ...items,
        ],
      ),
    );
  }
}

class _CatalogoCard extends StatelessWidget {
  const _CatalogoCard({
    required this.titulo,
    required this.detalle,
    required this.activo,
    required this.onEditar,
    required this.onActivo,
    required this.onEliminar,
  });

  final String titulo;
  final String detalle;
  final bool activo;
  final VoidCallback onEditar;
  final ValueChanged<bool> onActivo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: activo ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.sombraTarjeta(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalle,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
            Switch.adaptive(value: activo, onChanged: onActivo),
          ],
        ),
      ),
    );
  }
}

Future<void> _guardar(
  WidgetRef ref,
  Future<Result<void>> Function() accion,
  void Function(String) onMensaje,
) async {
  final Result<void> resultado = await accion();
  if (resultado is Failure<void>) {
    onMensaje(resultado.message);
  } else {
    onMensaje('Catálogo actualizado.');
  }
}

String _idUnico(String base, Set<String> existentes) {
  if (!existentes.contains(base)) return base;
  int i = 2;
  while (existentes.contains('${base}_$i')) {
    i++;
  }
  return '${base}_$i';
}

Future<void> _abrirEdificio(
  BuildContext context,
  WidgetRef ref,
  List<EdificioCatalogo> items,
  EdificioCatalogo? item,
) async {
  final EdificioCatalogo? resultado = await showDialog<EdificioCatalogo>(
    context: context,
    builder: (_) => _EdificioDialog(item: item, items: items),
  );
  if (resultado == null) return;
  final Result<void> r = await ref
      .read(catalogoRepositoryProvider)
      .guardarEdificio(resultado);
  if (r is Failure<void> && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(r.message)));
  }
}

Future<void> _abrirSitio(
  BuildContext context,
  WidgetRef ref,
  List<SitioReporteCatalogo> items,
  SitioReporteCatalogo? item,
) async {
  final SitioReporteCatalogo? resultado =
      await showDialog<SitioReporteCatalogo>(
        context: context,
        builder: (_) => _SitioDialog(item: item, items: items),
      );
  if (resultado == null) return;
  final Result<void> r = await ref
      .read(catalogoRepositoryProvider)
      .guardarSitio(resultado);
  if (r is Failure<void> && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(r.message)));
  }
}

Future<void> _confirmarEliminar(
  BuildContext context,
  WidgetRef ref,
  String nombre,
  Future<Result<void>> Function() accion,
  void Function(String) onMensaje,
) async {
  final bool? confirmar = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Eliminar del catálogo'),
      content: Text(
        '¿Eliminar "$nombre"? Esta acción no se puede deshacer. Los reportes '
        'anteriores conservarán el texto que ya tienen guardado.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmar != true) return;
  final Result<void> r = await accion();
  if (r is Failure<void>) {
    onMensaje(r.message);
  } else {
    ref.invalidate(edificiosCatalogoProvider);
    ref.invalidate(sitiosCatalogoProvider);
    ref.invalidate(tiposDanoCatalogoProvider);
    ref.invalidate(zonasCatalogoProvider);
    onMensaje('Elemento eliminado del catálogo.');
  }
}

Future<void> _abrirTipoDano(
  BuildContext context,
  WidgetRef ref,
  List<TipoDanoCatalogo> items,
  List<SitioReporteCatalogo> sitios,
  TipoDanoCatalogo? item,
) async {
  final TipoDanoCatalogo? resultado = await showDialog<TipoDanoCatalogo>(
    context: context,
    builder: (_) => _TipoDanoDialog(item: item, items: items, sitios: sitios),
  );
  if (resultado == null) return;
  final Result<void> r = await ref
      .read(catalogoRepositoryProvider)
      .guardarTipoDano(resultado);
  if (r is Failure<void> && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(r.message)));
  }
}

Future<void> _abrirNombre(
  BuildContext context,
  WidgetRef ref,
  List<String> nombresExistentes, {
  required String? nombreInicial,
  required Future<Result<void>> Function(String nombre) onGuardar,
  required void Function(String) onMensaje,
}) async {
  final String? nombre = await showDialog<String>(
    context: context,
    builder: (_) => _NombreDialog(
      titulo: nombreInicial == null ? 'Agregar' : 'Editar',
      nombreInicial: nombreInicial,
      nombresExistentes: nombresExistentes
          .where((String n) => n != nombreInicial)
          .toList(),
    ),
  );
  if (nombre == null) return;
  final Result<void> r = await onGuardar(nombre);
  if (r is Failure<void>) {
    onMensaje(r.message);
  } else {
    ref.invalidate(tiposDanoCatalogoProvider);
    ref.invalidate(zonasCatalogoProvider);
    onMensaje('Catálogo actualizado.');
  }
}

class _EdificioDialog extends StatefulWidget {
  const _EdificioDialog({required this.item, required this.items});

  final EdificioCatalogo? item;
  final List<EdificioCatalogo> items;

  @override
  State<_EdificioDialog> createState() => _EdificioDialogState();
}

class _EdificioDialogState extends State<_EdificioDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _pisos;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.item?.nombre ?? '');
    _pisos = TextEditingController(
      text: (widget.item?.pisos ?? <String>['Piso 1']).join(', '),
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _pisos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Agregar edificio' : 'Editar edificio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pisos,
            decoration: const InputDecoration(
              labelText: 'Pisos (separados por coma)',
              hintText: 'Piso 1, Piso 2, Piso 3',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final String nombre = _nombre.text.trim();
            final List<String> pisos = _pisos.text
                .split(',')
                .map((String p) => p.trim())
                .where((String p) => p.isNotEmpty)
                .toList();
            if (nombre.isEmpty || pisos.isEmpty) return;
            final bool duplicado = widget.items.any(
              (EdificioCatalogo e) =>
                  e.nombre.toLowerCase() == nombre.toLowerCase() &&
                  e.id != widget.item?.id,
            );
            if (duplicado) return;
            Navigator.pop(
              context,
              EdificioCatalogo(
                id:
                    widget.item?.id ??
                    _idUnico(
                      slugCatalogo(nombre),
                      widget.items.map((EdificioCatalogo e) => e.id).toSet(),
                    ),
                nombre: nombre,
                pisos: pisos,
                activo: widget.item?.activo ?? true,
                orden: widget.item?.orden ?? widget.items.length,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SitioDialog extends StatefulWidget {
  const _SitioDialog({required this.item, required this.items});

  final SitioReporteCatalogo? item;
  final List<SitioReporteCatalogo> items;

  @override
  State<_SitioDialog> createState() => _SitioDialogState();
}

class _SitioDialogState extends State<_SitioDialog> {
  late final TextEditingController _nombre;
  bool _requiereEdificio = false;
  bool _requierePiso = false;
  bool _muestraReferencia = true;
  bool _referenciaObligatoria = false;
  String? _tipoEspecial;

  @override
  void initState() {
    super.initState();
    final SitioReporteCatalogo? item = widget.item;
    _nombre = TextEditingController(text: item?.nombre ?? '');
    _requiereEdificio = item?.requiereEdificio ?? false;
    _requierePiso = item?.requierePiso ?? false;
    _muestraReferencia = item?.muestraReferencia ?? true;
    _referenciaObligatoria = item?.referenciaObligatoria ?? false;
    _tipoEspecial = item?.tipoEspecial;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esPersonalizado = widget.item?.esPersonalizado ?? true;
    return AlertDialog(
      title: Text(widget.item == null ? 'Agregar sitio' : 'Editar sitio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pide edificio'),
              value: _requiereEdificio,
              onChanged: esPersonalizado
                  ? (bool v) => setState(() => _requiereEdificio = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pide piso'),
              value: _requierePiso,
              onChanged: esPersonalizado
                  ? (bool v) => setState(() {
                      _requierePiso = v;
                      if (v) _requiereEdificio = true;
                    })
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Muestra referencia'),
              value: _muestraReferencia,
              onChanged: esPersonalizado
                  ? (bool v) => setState(() {
                      _muestraReferencia = v;
                      if (!v) _referenciaObligatoria = false;
                    })
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Referencia obligatoria'),
              value: _referenciaObligatoria,
              onChanged: esPersonalizado && _muestraReferencia
                  ? (bool v) => setState(() => _referenciaObligatoria = v)
                  : null,
            ),
            DropdownButtonFormField<String?>(
              initialValue: _tipoEspecial,
              decoration: const InputDecoration(labelText: 'Comportamiento'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Ninguno')),
                DropdownMenuItem(value: 'bano', child: Text('Baño')),
                DropdownMenuItem(value: 'escaleras', child: Text('Escaleras')),
                DropdownMenuItem(value: 'ascensor', child: Text('Ascensor')),
                DropdownMenuItem(
                  value: 'zona_exterior',
                  child: Text('Zona exterior'),
                ),
              ],
              onChanged: esPersonalizado
                  ? (String? v) => setState(() {
                      _tipoEspecial = v;
                      if (v == 'bano' || v == 'escaleras' || v == 'ascensor') {
                        _requiereEdificio = true;
                        _requierePiso = true;
                      }
                      if (v == 'zona_exterior') {
                        _requiereEdificio = false;
                        _requierePiso = false;
                        _muestraReferencia = true;
                        _referenciaObligatoria = true;
                      }
                    })
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final String nombre = _nombre.text.trim();
            if (nombre.isEmpty) return;
            final bool duplicado = widget.items.any(
              (SitioReporteCatalogo e) =>
                  e.nombre.toLowerCase() == nombre.toLowerCase() &&
                  e.id != widget.item?.id,
            );
            if (duplicado) return;
            Navigator.pop(
              context,
              SitioReporteCatalogo(
                id:
                    widget.item?.id ??
                    _idUnico(
                      slugCatalogo(nombre),
                      widget.items
                          .map((SitioReporteCatalogo e) => e.id)
                          .toSet(),
                    ),
                nombre: nombre,
                slug: widget.item?.slug ?? 'otro',
                requiereEdificio: _requiereEdificio,
                requierePiso: _requierePiso,
                muestraReferencia: _muestraReferencia,
                referenciaObligatoria: _referenciaObligatoria,
                tipoEspecial: _tipoEspecial,
                activo: widget.item?.activo ?? true,
                orden: widget.item?.orden ?? widget.items.length,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _TipoDanoDialog extends StatefulWidget {
  const _TipoDanoDialog({
    required this.item,
    required this.items,
    required this.sitios,
  });

  final TipoDanoCatalogo? item;
  final List<TipoDanoCatalogo> items;
  final List<SitioReporteCatalogo> sitios;

  @override
  State<_TipoDanoDialog> createState() => _TipoDanoDialogState();
}

class _TipoDanoDialogState extends State<_TipoDanoDialog> {
  late final TextEditingController _nombre;
  late bool _todos;
  late final Set<String> _seleccionados;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.item?.nombre ?? '');
    _todos = widget.item == null
        ? widget.sitios.isEmpty
        : widget.item!.sitios.isEmpty;
    _seleccionados = <String>{...?widget.item?.sitios};
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Agregar tipo de daño' : 'Editar tipo de daño',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Todos los sitios'),
              value: _todos,
              onChanged: (bool? v) {
                setState(() {
                  _todos = v ?? false;
                  if (!_todos) _seleccionados.clear();
                });
              },
            ),
            const Divider(height: 8),
            SizedBox(
              height: 230,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final SitioReporteCatalogo sitio in widget.sitios)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(sitio.nombre),
                      value: _todos || _seleccionados.contains(sitio.id),
                      onChanged: _todos
                          ? null
                          : (bool? v) {
                              setState(() {
                                if (v == true) {
                                  _seleccionados.add(sitio.id);
                                } else {
                                  _seleccionados.remove(sitio.id);
                                }
                              });
                            },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final String nombre = _nombre.text.trim();
            if (nombre.isEmpty) return;
            if (!_todos && _seleccionados.isEmpty) return;
            final bool duplicado = widget.items.any(
              (TipoDanoCatalogo t) =>
                  t.nombre.toLowerCase() == nombre.toLowerCase() &&
                  t.id != widget.item?.id,
            );
            if (duplicado) return;
            Navigator.pop(
              context,
              TipoDanoCatalogo(
                id:
                    widget.item?.id ??
                    _idUnico(
                      slugCatalogo(nombre),
                      widget.items.map((TipoDanoCatalogo t) => t.id).toSet(),
                    ),
                nombre: nombre,
                sitios: _todos
                    ? const <String>[]
                    : (_seleccionados.toList()..sort()),
                activo: widget.item?.activo ?? true,
                orden: widget.item?.orden ?? widget.items.length,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _NombreDialog extends StatefulWidget {
  const _NombreDialog({
    required this.titulo,
    required this.nombresExistentes,
    this.nombreInicial,
  });

  final String titulo;
  final List<String> nombresExistentes;
  final String? nombreInicial;

  @override
  State<_NombreDialog> createState() => _NombreDialogState();
}

class _NombreDialogState extends State<_NombreDialog> {
  late final TextEditingController _nombre;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _nombre,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final String nombre = _nombre.text.trim();
            if (nombre.isEmpty) return;
            final bool duplicado = widget.nombresExistentes.any(
              (String n) => n.toLowerCase() == nombre.toLowerCase(),
            );
            if (duplicado) return;
            Navigator.pop(context, nombre);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
