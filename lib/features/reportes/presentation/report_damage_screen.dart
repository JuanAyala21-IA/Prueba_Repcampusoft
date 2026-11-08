import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/catalogo_edificios.dart';
import '../../../core/constants/catalogo_espacios.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/image_preview.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/comprimir_imagen.dart';
import '../../catalogos/data/providers/catalogo_providers.dart';
import '../../catalogos/domain/catalogos.dart';
import '../../catalogos/presentation/catalogos_screen.dart';
import '../../auth/domain/rol_enum.dart';
import '../domain/reporte.dart';
import '../domain/reporte_repository.dart';

/// Pantalla 8: Reportar daños (RF-11, pantalla 8.png). Formulario conectado
/// al repositorio de reportes inyectado en main.dart (reportesOverrides).
///
/// El bloque de ubicación es adaptativo: al elegir el tipo de espacio
/// (aula, baño, laboratorio, pasillo, zona exterior, etc.) se muestran solo
/// los campos que aplican. El tipo de daño también se filtra por espacio.
///
/// Contrato 6.2/8.1: la evidencia foto se comprime a ~500 KB JPEG (RNF-06) y
/// viaja en el mismo batch atómico de create. El estado inicial es
/// 'Pendiente' (RF-11) y el identificador del reporte se muestra en el dialogo
/// de confirmación (RF-16/RF-17).
class ReportDamageScreen extends ConsumerStatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  ConsumerState<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends ConsumerState<ReportDamageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _espacioCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  SitioReporteCatalogo? _sitio;
  String? _tipoDano;
  String? _edificio;
  String? _piso;
  String? _generoBano;
  String? _tramoEscaleras;
  String? _ascensor;
  String? _pisoAscensor;
  String? _zonaExterior;
  String? _fotoBase64;
  Uint8List? _fotoPreviewBytes;
  bool _procesandoFoto = false;
  bool _enviando = false;
  bool _sinConexion = false;

  TipoEspacio? get _tipoEspacio => _sitio?.tipoBase;
  String? get _tipoEspecial => _sitio?.tipoEspecial;
  bool get _requiereEdificio => _sitio?.esPersonalizado == true
      ? _sitio!.requiereEdificio
      : (_tipoEspacio?.requiereEdificio ?? false);
  bool get _requierePiso => _sitio?.esPersonalizado == true
      ? _sitio!.requierePiso
      : (_tipoEspacio?.requierePiso ?? false);
  bool get _muestraReferencia => _sitio?.esPersonalizado == true
      ? _sitio!.muestraReferencia
      : (_tipoEspacio?.muestraReferencia ?? false);
  bool get _referenciaObligatoria => _sitio?.esPersonalizado == true
      ? _sitio!.referenciaObligatoria
      : (_tipoEspacio?.referenciaObligatoria ?? false);

  @override
  void dispose() {
    _espacioCtrl.dispose();
    _referenciaCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  /// Al cambiar de sitio se limpian los campos del sitio anterior para no
  /// guardar datos inconsistentes (p. ej. un baño con salón).
  void _cambiarSitio(SitioReporteCatalogo? sitio) {
    setState(() {
      _sitio = sitio;
      _tipoDano = null;
      _edificio = null;
      _piso = null;
      _generoBano = null;
      _tramoEscaleras = null;
      _ascensor = null;
      _pisoAscensor = null;
      _zonaExterior = null;
      _espacioCtrl.clear();
      _referenciaCtrl.clear();
    });
  }

  List<EdificioCatalogo> _edificiosActuales() =>
      ref.read(edificiosCatalogoProvider).value ?? edificiosPorDefecto();

  EdificioCatalogo? _edificioPorNombre(
    List<EdificioCatalogo> edificios,
    String? nombre,
  ) {
    for (final EdificioCatalogo edificio in edificios) {
      if (edificio.nombre == nombre) return edificio;
    }
    return null;
  }

  List<String> _edificiosDisponibles(List<EdificioCatalogo> edificios) {
    final List<String> todos = edificios
        .where((EdificioCatalogo e) => e.activo)
        .map((EdificioCatalogo e) => e.nombre)
        .toList();
    if (_tipoEspacio == TipoEspacio.salaComputo) {
      return todos
          .where((String n) => CatalogoEdificios.salasComputo.contains(n))
          .toList();
    }
    if (_tipoEspacio == TipoEspacio.cafeteria) {
      return todos
          .where((String n) => CatalogoEdificios.cafeterias.contains(n))
          .toList();
    }
    return todos;
  }

  List<String> _pisosDisponibles(List<EdificioCatalogo> edificios) {
    if (_tipoEspacio == TipoEspacio.salaComputo) {
      return CatalogoEspacios.pisosSalaComputo;
    }
    return _edificioPorNombre(edificios, _edificio)?.pisos ?? const <String>[];
  }

  List<String> _tramosDisponibles(List<EdificioCatalogo> edificios) {
    final List<String> pisos = _pisosDisponibles(edificios);
    return <String>[
      for (int i = 1; i < pisos.length; i++) 'Piso $i a ${i + 1}',
    ];
  }

  List<String> _pisosAscensor(List<EdificioCatalogo> edificios) {
    return <String>[..._pisosDisponibles(edificios), 'Cabina', 'No aplica'];
  }

  /// Ajusta los pisos disponibles al edificio elegido y limpia selecciones
  /// que dejan de ser válidas (p. ej. Piso 6 al pasar del Edificio A al C).
  void _cambiarEdificio(String? edificio) {
    final List<EdificioCatalogo> edificios = _edificiosActuales();
    setState(() {
      _edificio = edificio;
      if (!_pisosDisponibles(edificios).contains(_piso)) _piso = null;
      if (!_tramosDisponibles(edificios).contains(_tramoEscaleras)) {
        _tramoEscaleras = null;
      }
      if (!_pisosAscensor(edificios).contains(_pisoAscensor)) {
        _pisoAscensor = null;
      }
    });
  }

  bool get _muestraEspacioTexto {
    final tipo = _tipoEspacio;
    if (tipo == null) return false;
    if (_sitio?.esPersonalizado == true) {
      return !<String?>[
        'bano',
        'escaleras',
        'ascensor',
        'zona_exterior',
      ].contains(_tipoEspecial);
    }
    return tipo == TipoEspacio.aula ||
        tipo == TipoEspacio.laboratorio ||
        tipo == TipoEspacio.salaComputo ||
        tipo == TipoEspacio.oficina ||
        tipo == TipoEspacio.auditorio ||
        tipo == TipoEspacio.biblioteca ||
        tipo == TipoEspacio.otro;
  }

  String get _etiquetaEspacio {
    if (_sitio?.esPersonalizado == true) return 'Detalle del sitio';
    return switch (_tipoEspacio!) {
      TipoEspacio.aula => 'Salón',
      TipoEspacio.laboratorio => 'Laboratorio',
      TipoEspacio.salaComputo => 'Sala de cómputo',
      TipoEspacio.oficina => 'Dependencia',
      TipoEspacio.auditorio => 'Nombre del auditorio',
      TipoEspacio.biblioteca => 'Zona de la biblioteca',
      TipoEspacio.otro => 'Descripción de la ubicación',
      _ => 'Ubicación',
    };
  }

  String get _hintEspacio {
    if (_sitio?.esPersonalizado == true) {
      return 'Ej. Salón 501, oficina 2, bloque norte';
    }
    return switch (_tipoEspacio!) {
      TipoEspacio.aula => 'Ej. 203',
      TipoEspacio.laboratorio => 'Ej. Laboratorio de Química',
      TipoEspacio.salaComputo => 'Ej. Sala de cómputo 305',
      TipoEspacio.oficina => 'Ej. Registro y Control',
      TipoEspacio.auditorio => 'Ej. Auditorio principal',
      TipoEspacio.biblioteca => 'Ej. Sala de lectura',
      TipoEspacio.otro => 'Ej. Pasillo técnico detrás de la cafetería',
      _ => 'Describe el espacio',
    };
  }

  String get _hintReferencia {
    if (_sitio?.esPersonalizado == true) {
      return 'Ej. Frente a la entrada, junto a la cafetería';
    }
    return switch (_tipoEspacio!) {
      TipoEspacio.aula => 'Ej. Ala norte, junto al laboratorio 2',
      TipoEspacio.laboratorio => 'Ej. Junto a la ventana o al tablero',
      TipoEspacio.salaComputo => 'Ej. Junto a la puerta o al tablero',
      TipoEspacio.bano => 'Ej. Junto a las escaleras',
      TipoEspacio.pasillo => 'Ej. Entre las aulas 201 y 203',
      TipoEspacio.oficina => 'Ej. Segundo piso, ala oriental',
      TipoEspacio.auditorio => 'Ej. Platea, escenario o cabina',
      TipoEspacio.biblioteca => 'Ej. Segundo piso, junto a la hemeroteca',
      TipoEspacio.escaleras => 'Ej. Escaleras del ala norte',
      TipoEspacio.ascensor => 'Ej. Frente a la recepción',
      TipoEspacio.zonaExterior => 'Ej. Frente al Edificio B',
      TipoEspacio.parqueadero => 'Ej. Cerca de la entrada o puesto 45',
      _ => 'Ej. Junto a la entrada',
    };
  }

  String get _espacioBano {
    final genero = _generoBano!;
    return genero == 'Hombre' ? 'Baño de hombres' : 'Baño de mujeres';
  }

  String _conPrefijoSalon(String texto) {
    final lower = texto.toLowerCase();
    return (lower.startsWith('salón') || lower.startsWith('salon'))
        ? texto
        : 'Salón $texto';
  }

  String get _espacioParaGuardar {
    final String texto = _espacioCtrl.text.trim();
    if (_sitio?.esPersonalizado == true) {
      return switch (_tipoEspecial) {
        'bano' => _espacioBano,
        'escaleras' => 'Escaleras',
        'ascensor' =>
          'Ascensor ${_ascensor!.replaceFirst('Ascensor ', '').toLowerCase()}',
        'zona_exterior' => _zonaExterior!,
        _ => texto.isEmpty ? _sitio!.nombre : texto,
      };
    }
    final TipoEspacio tipo = _tipoEspacio!;
    return switch (tipo) {
      TipoEspacio.aula => _conPrefijoSalon(texto),
      TipoEspacio.laboratorio => texto,
      TipoEspacio.salaComputo => texto,
      TipoEspacio.bano => _espacioBano,
      TipoEspacio.pasillo => 'Pasillo',
      TipoEspacio.oficina =>
        texto.toLowerCase().startsWith('oficina') ? texto : 'Oficina de $texto',
      TipoEspacio.auditorio => texto,
      TipoEspacio.biblioteca => texto,
      TipoEspacio.cafeteria => 'Cafetería',
      TipoEspacio.escaleras => 'Escaleras',
      TipoEspacio.ascensor =>
        'Ascensor ${_ascensor!.replaceFirst('Ascensor ', '').toLowerCase()}',
      TipoEspacio.zonaExterior => _zonaExterior!,
      TipoEspacio.parqueadero => 'Parqueadero CAR',
      TipoEspacio.acceso => tipo.etiqueta,
      TipoEspacio.otro => texto,
    };
  }

  String? get _edificioParaGuardar {
    return (_requiereEdificio || _tipoEspacio == TipoEspacio.otro)
        ? _edificio
        : null;
  }

  String? get _pisoParaGuardar {
    if (_tipoEspecial == 'escaleras') return _tramoEscaleras;
    if (_tipoEspecial == 'ascensor') return _pisoAscensor;
    if (_requierePiso || _tipoEspacio == TipoEspacio.otro) return _piso;
    return null;
  }

  String? get _referenciaParaGuardar {
    if (!_muestraReferencia) return null;
    final String referencia = _referenciaCtrl.text.trim();
    return referencia.isEmpty ? null : referencia;
  }

  Future<void> _adjuntarFoto() async {
    final ImageSource? fuente = await mostrarSelectorFuenteImagen(context);
    if (fuente == null) return;
    if (!mounted) return;
    setState(() => _procesandoFoto = true);
    final XFile? archivo = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (archivo == null) {
      if (mounted) setState(() => _procesandoFoto = false);
      return;
    }
    // Compresión equilibrada: máx. 1280 px y ~150�?"250 KB
    // (ver data/comprimir_imagen.dart).
    Uint8List comprimida;
    try {
      comprimida = await comprimirImagenReporte(archivo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesandoFoto = false);
      _mostrarAviso('No se pudo comprimir la imagen.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _procesandoFoto = false;
      _fotoPreviewBytes = comprimida;
      _fotoBase64 = base64Encode(comprimida);
    });
  }

  void _quitarFoto() {
    setState(() {
      _fotoBase64 = null;
      _fotoPreviewBytes = null;
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final SitioReporteCatalogo? sitio = _sitio;
    if (sitio == null || _tipoDano == null) {
      _mostrarAviso('Completa la ubicación y el tipo de daño.');
      return;
    }

    // RF-11/RNF-04: bloquea el envio con foto si no hay conexion (la foto
    // exige conexion activa 6.2/8.1). Sin foto si se permite en modo local.
    final bool conexion = await ref
        .read(sondaConectividadProvider)
        .hayConexion();
    if (!conexion && _fotoBase64 != null) {
      setState(() => _sinConexion = true);
      _mostrarAviso('Sin conexión: quita la foto o conectate para reportar.');
      return;
    }

    setState(() => _enviando = true);
    try {
      final Result<String> resultado = await ref
          .read(reporteRepositoryProvider)
          .crear(
            BorradorReporte(
              tipoUbicacion: sitio.tipoBase,
              tipoUbicacionNombre: sitio.nombre,
              edificio: _edificioParaGuardar,
              piso: _pisoParaGuardar,
              espacio: _espacioParaGuardar,
              referencia: _referenciaParaGuardar,
              tipoDano: _tipoDano!,
              descripcion: _descripcionCtrl.text.trim(),
              fotoBase64: _fotoBase64,
            ),
          );

      if (!mounted) return;
      switch (resultado) {
        case Success():
          _irAMisReportes();
        case Failure(message: final mensaje):
          _mostrarAviso(mensaje);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarAviso('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  /// Al enviar el reporte se lleva al usuario directo a "Tus reportes" para
  /// que vea el reporte recién creado (en lugar de dejarlo en el formulario).
  void _irAMisReportes() {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // `go` reemplaza la ruta actual: al volver atrás no se regresa al
    // formulario ya enviado.
    context.go(AppRoutes.misReportes);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Ya aparece en Tus reportes.'),
        ),
      );
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final Sesion sesion = ref.watch(sesionProvider);
    if (sesion.rol == RolEnum.mantenimiento ||
        sesion.rol == RolEnum.superadministrador) {
      return const CatalogosScreen();
    }
    final List<EdificioCatalogo> edificios =
        ref.watch(edificiosCatalogoProvider).value ?? edificiosPorDefecto();
    final List<SitioReporteCatalogo> sitios =
        (ref.watch(sitiosCatalogoProvider).value ?? sitiosPorDefecto())
            .where((SitioReporteCatalogo s) => s.activo)
            .toList();
    final List<String> tiposDano =
        (ref.watch(tiposDanoCatalogoProvider).value ?? tiposDanoPorDefecto())
            .where(
              (TipoDanoCatalogo t) =>
                  t.activo &&
                  (t.sitios.isEmpty ||
                      (_sitio != null && t.sitios.contains(_sitio!.id))),
            )
            .map((TipoDanoCatalogo t) => t.nombre)
            .toList();
    final List<String> zonas =
        (ref.watch(zonasCatalogoProvider).value ?? zonasPorDefecto())
            .where((ZonaExteriorCatalogo z) => z.activo)
            .map((ZonaExteriorCatalogo z) => z.nombre)
            .toList();
    final List<String> edificiosDisponibles = _edificiosDisponibles(edificios);
    final List<String> pisosDisponibles = _pisosDisponibles(edificios);
    final List<String> tramosDisponibles = _tramosDisponibles(edificios);
    final List<String> pisosAscensor = _pisosAscensor(edificios);

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UtsHeader(titulo: 'Reportar daños', mostrarLogo: false),
                  const SizedBox(height: 18),
                  if (_sinConexion)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.estadoPendiente.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.estadoPendiente,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin conexión: la foto de evidencia requiere '
                              'conexión activa. Quita la foto o reintenta.',
                              style: AppTypography.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  _CampoCatalogo(
                    etiqueta: '¿Dónde ocurrió?',
                    valores: sitios
                        .map((SitioReporteCatalogo s) => s.nombre)
                        .toList(),
                    valor: _sitio?.nombre,
                    onChanged: (nombre) {
                      if (nombre == null) {
                        _cambiarSitio(null);
                        return;
                      }
                      final SitioReporteCatalogo sitio = sitios.firstWhere(
                        (SitioReporteCatalogo s) => s.nombre == nombre,
                      );
                      _cambiarSitio(sitio);
                    },
                    validator: _obligatorio,
                  ),
                  if (_sitio != null) ...[
                    const SizedBox(height: 18),
                    // La clave reinicia los campos condicionales cuando cambia
                    // el sitio, evitando valores arrastrados.
                    KeyedSubtree(
                      key: ValueKey(_sitio!.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_requiereEdificio ||
                              _tipoEspacio == TipoEspacio.otro) ...[
                            _CampoCatalogo(
                              etiqueta: _requiereEdificio
                                  ? 'Edificio'
                                  : 'Edificio (opcional)',
                              valores: edificiosDisponibles,
                              valor: _edificio,
                              onChanged: _cambiarEdificio,
                              validator: _requiereEdificio
                                  ? _obligatorio
                                  : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if ((_requierePiso ||
                                  _tipoEspacio == TipoEspacio.otro) &&
                              _edificio != null) ...[
                            _CampoCatalogo(
                              key: ValueKey('piso-${_edificio ?? ''}'),
                              etiqueta: _requierePiso
                                  ? 'Piso'
                                  : 'Piso (opcional)',
                              valores: pisosDisponibles,
                              valor: _piso,
                              onChanged: (v) => setState(() => _piso = v),
                              validator: _requierePiso ? _obligatorio : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspecial == 'escaleras' &&
                              _edificio != null) ...[
                            _CampoCatalogo(
                              key: ValueKey('tramo-${_edificio ?? ''}'),
                              etiqueta: 'Tramo',
                              valores: tramosDisponibles,
                              valor: _tramoEscaleras,
                              onChanged: (v) =>
                                  setState(() => _tramoEscaleras = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspecial == 'ascensor' &&
                              _edificio != null) ...[
                            _CampoCatalogo(
                              etiqueta: 'Ascensor',
                              valores: CatalogoEspacios.ascensores,
                              valor: _ascensor,
                              onChanged: (v) => setState(() => _ascensor = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                            _CampoCatalogo(
                              key: ValueKey('piso-ascensor-${_edificio ?? ''}'),
                              etiqueta: 'Piso / cabina',
                              valores: pisosAscensor,
                              valor: _pisoAscensor,
                              onChanged: (v) =>
                                  setState(() => _pisoAscensor = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspecial == 'bano') ...[
                            _CampoCatalogo(
                              etiqueta: 'Baño',
                              valores: CatalogoEspacios.generosBano,
                              valor: _generoBano,
                              onChanged: (v) => setState(() => _generoBano = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_muestraEspacioTexto) ...[
                            LabelledField(
                              controlador: _espacioCtrl,
                              etiqueta: _etiquetaEspacio,
                              hint: _hintEspacio,
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspecial == 'zona_exterior') ...[
                            _CampoCatalogo(
                              etiqueta: 'Zona',
                              valores: zonas,
                              valor: _zonaExterior,
                              onChanged: (v) =>
                                  setState(() => _zonaExterior = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_muestraReferencia) ...[
                            LabelledField(
                              controlador: _referenciaCtrl,
                              etiqueta: _referenciaObligatoria
                                  ? 'Referencia'
                                  : 'Referencia (opcional)',
                              hint: _hintReferencia,
                              validator: _referenciaObligatoria
                                  ? _obligatorio
                                  : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _CampoCatalogo(
                            etiqueta: 'Tipo de daño',
                            valores: tiposDano,
                            valor: _tipoDano,
                            onChanged: (v) => setState(() => _tipoDano = v),
                            validator: _obligatorio,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LabelledField(
                    controlador: _descripcionCtrl,
                    etiqueta: 'Descripción',
                    hint: 'Detalla el estado del daño',
                    multiline: true,
                    validator: _obligatorio,
                  ),
                  const SizedBox(height: 18),
                  _buildAdjuntarFoto(context),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    texto: 'ENVIAR REPORTE',
                    cargando: _enviando,
                    onPressed: _enviando ? null : _enviar,
                    variante: Variante.verdeOscuro,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjuntarFoto(BuildContext context) {
    if (_procesandoFoto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text('Procesando imagen...'),
          ],
        ),
      );
    }

    final Uint8List? bytes = _fotoPreviewBytes;
    if (bytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => mostrarImagenAmpliada(
              context,
              bytes,
              descripcion: 'Foto del daño',
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    bytes,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Quitar foto',
                      onPressed: _quitarFoto,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: IndicadorAmpliarImagen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Foto lista para enviar',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.estadoSolucionado,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _adjuntarFoto,
                icon: const Icon(Icons.change_circle_outlined),
                label: const Text('Cambiar foto'),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: _enviando ? null : _adjuntarFoto,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para tomar una foto o elegir de la galería',
              style: AppTypography.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '(opcional)',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de selección estilo catálogo (dropdown RF-11) con estética UTS.
class _CampoCatalogo extends StatelessWidget {
  const _CampoCatalogo({
    super.key,
    required this.etiqueta,
    required this.valores,
    required this.valor,
    required this.onChanged,
    required this.validator,
  });

  final String etiqueta;
  final List<String> valores;
  final String? valor;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: AppTypography.textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          validator: validator,
          decoration: const InputDecoration(
            hintText: 'Selecciona',
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          ),
          items: valores
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
