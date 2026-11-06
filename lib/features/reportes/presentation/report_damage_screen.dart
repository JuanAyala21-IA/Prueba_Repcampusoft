import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/catalogo_edificios.dart';
import '../../../core/constants/catalogo_espacios.dart';
import '../../../core/constants/catalogo_tipos_dano.dart';
import '../../../core/routes/app_router.dart';
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

  TipoEspacio? _tipoEspacio;
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

  @override
  void dispose() {
    _espacioCtrl.dispose();
    _referenciaCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  /// Al cambiar de tipo de espacio se limpian los campos del tipo anterior
  /// para no guardar datos inconsistentes (p. ej. un baño con salón).
  void _cambiarTipoEspacio(TipoEspacio? tipo) {
    setState(() {
      _tipoEspacio = tipo;
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

  /// Ajusta los pisos disponibles al edificio elegido y limpia selecciones
  /// que dejan de ser válidas (p. ej. Piso 6 al pasar del Edificio A al C).
  void _cambiarEdificio(String? edificio) {
    setState(() {
      _edificio = edificio;
      if (!_pisosDisponibles.contains(_piso)) _piso = null;
      if (!CatalogoEspacios.tramosEscalerasPara(edificio)
          .contains(_tramoEscaleras)) {
        _tramoEscaleras = null;
      }
      if (!CatalogoEspacios.pisosAscensorPara(edificio)
          .contains(_pisoAscensor)) {
        _pisoAscensor = null;
      }
    });
  }

  List<String> get _edificiosDisponibles => switch (_tipoEspacio) {
    TipoEspacio.salaComputo => CatalogoEdificios.salasComputo,
    TipoEspacio.cafeteria => CatalogoEdificios.cafeterias,
    _ => CatalogoEdificios.valores,
  };

  List<String> get _pisosDisponibles => _tipoEspacio == TipoEspacio.salaComputo
      ? CatalogoEspacios.pisosSalaComputo
      : CatalogoEspacios.pisosPara(_edificio);

  bool get _muestraEspacioTexto {
    final tipo = _tipoEspacio;
    if (tipo == null) return false;
    return tipo == TipoEspacio.aula ||
        tipo == TipoEspacio.laboratorio ||
        tipo == TipoEspacio.salaComputo ||
        tipo == TipoEspacio.oficina ||
        tipo == TipoEspacio.auditorio ||
        tipo == TipoEspacio.biblioteca ||
        tipo == TipoEspacio.otro;
  }

  String get _etiquetaEspacio => switch (_tipoEspacio!) {
    TipoEspacio.aula => 'Salón',
    TipoEspacio.laboratorio => 'Laboratorio',
    TipoEspacio.salaComputo => 'Sala de cómputo',
    TipoEspacio.oficina => 'Dependencia',
    TipoEspacio.auditorio => 'Nombre del auditorio',
    TipoEspacio.biblioteca => 'Zona de la biblioteca',
    TipoEspacio.otro => 'Descripción de la ubicación',
    _ => 'Ubicación',
  };

  String get _hintEspacio => switch (_tipoEspacio!) {
    TipoEspacio.aula => 'Ej. 203',
    TipoEspacio.laboratorio => 'Ej. Laboratorio de Química',
    TipoEspacio.salaComputo => 'Ej. Sala de cómputo 305',
    TipoEspacio.oficina => 'Ej. Registro y Control',
    TipoEspacio.auditorio => 'Ej. Auditorio principal',
    TipoEspacio.biblioteca => 'Ej. Sala de lectura',
    TipoEspacio.otro => 'Ej. Pasillo técnico detrás de la cafetería',
    _ => 'Describe el espacio',
  };

  String get _hintReferencia => switch (_tipoEspacio!) {
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
    final tipo = _tipoEspacio!;
    final texto = _espacioCtrl.text.trim();
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
    final tipo = _tipoEspacio!;
    return (tipo.requiereEdificio || tipo == TipoEspacio.otro)
        ? _edificio
        : null;
  }

  String? get _pisoParaGuardar {
    final tipo = _tipoEspacio!;
    if (tipo == TipoEspacio.escaleras) return _tramoEscaleras;
    if (tipo == TipoEspacio.ascensor) return _pisoAscensor;
    if (tipo == TipoEspacio.otro) return _piso;
    return tipo.requierePiso ? _piso : null;
  }

  String? get _referenciaParaGuardar {
    final tipo = _tipoEspacio!;
    if (!tipo.muestraReferencia) return null;
    final referencia = _referenciaCtrl.text.trim();
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
    // Compresión equilibrada: máx. 1280 px y ~150–250 KB
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

    final tipo = _tipoEspacio;
    if (tipo == null || _tipoDano == null) {
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
              tipoUbicacion: tipo,
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
                    valores: TipoEspacio.values
                        .where((tipo) => tipo.seleccionable)
                        .map((tipo) => tipo.etiqueta)
                        .toList(),
                    valor: _tipoEspacio?.etiqueta,
                    onChanged: (etiqueta) {
                      if (etiqueta == null) {
                        _cambiarTipoEspacio(null);
                        return;
                      }
                      final tipo = TipoEspacio.values.firstWhere(
                        (tipo) => tipo.etiqueta == etiqueta,
                      );
                      _cambiarTipoEspacio(tipo);
                    },
                    validator: _obligatorio,
                  ),
                  if (_tipoEspacio != null) ...[
                    const SizedBox(height: 18),
                    // La clave reinicia los campos condicionales cuando cambia
                    // el tipo de espacio, evitando valores arrastrados.
                    KeyedSubtree(
                      key: ValueKey(_tipoEspacio!.slug),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_tipoEspacio!.requiereEdificio ||
                              _tipoEspacio == TipoEspacio.otro) ...[
                            _CampoCatalogo(
                              etiqueta: _tipoEspacio == TipoEspacio.otro
                                  ? 'Edificio (opcional)'
                                  : 'Edificio',
                              valores: _edificiosDisponibles,
                              valor: _edificio,
                              onChanged: _cambiarEdificio,
                              validator: _tipoEspacio!.requiereEdificio
                                  ? _obligatorio
                                  : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if ((_tipoEspacio!.requierePiso ||
                                  _tipoEspacio == TipoEspacio.otro) &&
                              _edificio != null) ...[
                            _CampoCatalogo(
                              key: ValueKey('piso-${_edificio ?? ''}'),
                              etiqueta: _tipoEspacio == TipoEspacio.otro
                                  ? 'Piso (opcional)'
                                  : 'Piso',
                              valores: _pisosDisponibles,
                              valor: _piso,
                              onChanged: (v) => setState(() => _piso = v),
                              validator: _tipoEspacio!.requierePiso
                                  ? _obligatorio
                                  : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspacio == TipoEspacio.escaleras &&
                              _edificio != null) ...[
                            _CampoCatalogo(
                              key: ValueKey('tramo-${_edificio ?? ''}'),
                              etiqueta: 'Tramo',
                              valores: CatalogoEspacios.tramosEscalerasPara(
                                _edificio,
                              ),
                              valor: _tramoEscaleras,
                              onChanged: (v) =>
                                  setState(() => _tramoEscaleras = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspacio == TipoEspacio.ascensor &&
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
                              valores: CatalogoEspacios.pisosAscensorPara(
                                _edificio,
                              ),
                              valor: _pisoAscensor,
                              onChanged: (v) =>
                                  setState(() => _pisoAscensor = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspacio == TipoEspacio.bano) ...[
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
                          if (_tipoEspacio == TipoEspacio.zonaExterior) ...[
                            _CampoCatalogo(
                              etiqueta: 'Zona',
                              valores: CatalogoEspacios.zonasExteriores,
                              valor: _zonaExterior,
                              onChanged: (v) =>
                                  setState(() => _zonaExterior = v),
                              validator: _obligatorio,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (_tipoEspacio!.muestraReferencia) ...[
                            LabelledField(
                              controlador: _referenciaCtrl,
                              etiqueta: _tipoEspacio!.referenciaObligatoria
                                  ? 'Referencia'
                                  : 'Referencia (opcional)',
                              hint: _hintReferencia,
                              validator: _tipoEspacio!.referenciaObligatoria
                                  ? _obligatorio
                                  : null,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _CampoCatalogo(
                            etiqueta: 'Tipo de daño',
                            valores: CatalogoTiposDano.para(_tipoEspacio),
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
