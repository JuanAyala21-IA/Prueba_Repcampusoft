import '../../../core/utils/result.dart';
import 'catalogos.dart';

/// Persistencia de los catálogos editables de reportes.
abstract interface class CatalogoRepository {
  Stream<List<EdificioCatalogo>> watchEdificios();
  Stream<List<SitioReporteCatalogo>> watchSitios();
  Stream<List<TipoDanoCatalogo>> watchTiposDano();
  Stream<List<ZonaExteriorCatalogo>> watchZonas();

  Future<Result<void>> guardarEdificio(EdificioCatalogo edificio);
  Future<Result<void>> guardarSitio(SitioReporteCatalogo sitio);
  Future<Result<void>> guardarTipoDano(TipoDanoCatalogo tipo);
  Future<Result<void>> guardarZona(ZonaExteriorCatalogo zona);

  /// Crea los documentos iniciales en Firestore si las colecciones están
  /// vacías. Es idempotente.
  Future<Result<void>> sembrarIniciales();
}
