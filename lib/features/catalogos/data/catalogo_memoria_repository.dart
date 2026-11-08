import '../../../core/utils/result.dart';
import '../domain/catalogo_repository.dart';
import '../domain/catalogos.dart';

/// Implementación en memoria usada como respaldo en pruebas y cuando no se
/// inyecta Firebase. Mantiene los catálogos iniciales del proyecto.
class CatalogoMemoriaRepository implements CatalogoRepository {
  CatalogoMemoriaRepository({
    List<EdificioCatalogo>? edificios,
    List<SitioReporteCatalogo>? sitios,
    List<TipoDanoCatalogo>? danos,
    List<ZonaExteriorCatalogo>? zonas,
  }) : _edificios = edificios ?? edificiosPorDefecto(),
       _sitios = sitios ?? sitiosPorDefecto(),
       _danos = danos ?? tiposDanoPorDefecto(),
       _zonas = zonas ?? zonasPorDefecto();

  final List<EdificioCatalogo> _edificios;
  final List<SitioReporteCatalogo> _sitios;
  final List<TipoDanoCatalogo> _danos;
  final List<ZonaExteriorCatalogo> _zonas;

  @override
  Stream<List<EdificioCatalogo>> watchEdificios() =>
      Stream<List<EdificioCatalogo>>.value(
        List<EdificioCatalogo>.of(_edificios),
      );

  @override
  Stream<List<SitioReporteCatalogo>> watchSitios() =>
      Stream<List<SitioReporteCatalogo>>.value(
        List<SitioReporteCatalogo>.of(_sitios),
      );

  @override
  Stream<List<TipoDanoCatalogo>> watchTiposDano() =>
      Stream<List<TipoDanoCatalogo>>.value(List<TipoDanoCatalogo>.of(_danos));

  @override
  Stream<List<ZonaExteriorCatalogo>> watchZonas() =>
      Stream<List<ZonaExteriorCatalogo>>.value(
        List<ZonaExteriorCatalogo>.of(_zonas),
      );

  @override
  Future<Result<void>> guardarEdificio(EdificioCatalogo edificio) async {
    _reemplazar(
      _edificios,
      edificio,
      (EdificioCatalogo e) => e.id == edificio.id,
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> guardarSitio(SitioReporteCatalogo sitio) async {
    _reemplazar(_sitios, sitio, (SitioReporteCatalogo s) => s.id == sitio.id);
    return const Success(null);
  }

  @override
  Future<Result<void>> guardarTipoDano(TipoDanoCatalogo tipo) async {
    _reemplazar(_danos, tipo, (TipoDanoCatalogo t) => t.id == tipo.id);
    return const Success(null);
  }

  @override
  Future<Result<void>> guardarZona(ZonaExteriorCatalogo zona) async {
    _reemplazar(_zonas, zona, (ZonaExteriorCatalogo z) => z.id == zona.id);
    return const Success(null);
  }

  @override
  Future<Result<void>> sembrarIniciales() async => const Success(null);

  void _reemplazar<T>(List<T> lista, T item, bool Function(T) coincide) {
    final int indice = lista.indexWhere(coincide);
    if (indice >= 0) {
      lista[indice] = item;
    } else {
      lista.add(item);
    }
  }
}
