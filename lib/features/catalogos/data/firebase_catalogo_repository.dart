import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/utils/result.dart';
import '../domain/catalogo_repository.dart';
import '../domain/catalogos.dart';

class FirebaseCatalogoRepository implements CatalogoRepository {
  FirebaseCatalogoRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  static const String _colEdificios = 'catalogos_edificios';
  static const String _colSitios = 'catalogos_sitios';
  static const String _colDanos = 'catalogos_danos';
  static const String _colZonas = 'catalogos_zonas';

  CollectionReference<Map<String, dynamic>> _col(String nombre) =>
      _firestore.collection(nombre);

  @override
  Stream<List<EdificioCatalogo>> watchEdificios() {
    return _col(_colEdificios)
        .orderBy('orden')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data = doc.data();
            final List<dynamic> pisos =
                (data['pisos'] as List<dynamic>?) ?? const <dynamic>[];
            return EdificioCatalogo(
              id: doc.id,
              nombre: data['nombre'] as String? ?? doc.id,
              pisos: pisos.map((dynamic p) => p.toString()).toList(),
              activo: data['activo'] as bool? ?? true,
              orden: (data['orden'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
  }

  @override
  Stream<List<SitioReporteCatalogo>> watchSitios() {
    return _col(_colSitios)
        .orderBy('orden')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data = doc.data();
            return SitioReporteCatalogo(
              id: doc.id,
              nombre: data['nombre'] as String? ?? doc.id,
              slug: data['slug'] as String? ?? 'otro',
              requiereEdificio: data['requiereEdificio'] as bool? ?? false,
              requierePiso: data['requierePiso'] as bool? ?? false,
              muestraReferencia: data['muestraReferencia'] as bool? ?? true,
              referenciaObligatoria:
                  data['referenciaObligatoria'] as bool? ?? false,
              tipoEspecial: data['tipoEspecial'] as String?,
              activo: data['activo'] as bool? ?? true,
              orden: (data['orden'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
  }

  @override
  Stream<List<TipoDanoCatalogo>> watchTiposDano() {
    return _col(_colDanos)
        .orderBy('orden')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data = doc.data();
            return TipoDanoCatalogo(
              id: doc.id,
              nombre: data['nombre'] as String? ?? doc.id,
              activo: data['activo'] as bool? ?? true,
              orden: (data['orden'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
  }

  @override
  Stream<List<ZonaExteriorCatalogo>> watchZonas() {
    return _col(_colZonas)
        .orderBy('orden')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data = doc.data();
            return ZonaExteriorCatalogo(
              id: doc.id,
              nombre: data['nombre'] as String? ?? doc.id,
              activo: data['activo'] as bool? ?? true,
              orden: (data['orden'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
  }

  @override
  Future<Result<void>> guardarEdificio(EdificioCatalogo edificio) {
    return _guardar(_colEdificios, edificio.id, <String, Object?>{
      'nombre': edificio.nombre.trim(),
      'pisos': edificio.pisos,
      'activo': edificio.activo,
      'orden': edificio.orden,
    });
  }

  @override
  Future<Result<void>> guardarSitio(SitioReporteCatalogo sitio) {
    return _guardar(_colSitios, sitio.id, <String, Object?>{
      'nombre': sitio.nombre.trim(),
      'slug': sitio.slug,
      'requiereEdificio': sitio.requiereEdificio,
      'requierePiso': sitio.requierePiso,
      'muestraReferencia': sitio.muestraReferencia,
      'referenciaObligatoria': sitio.referenciaObligatoria,
      'tipoEspecial': sitio.tipoEspecial,
      'activo': sitio.activo,
      'orden': sitio.orden,
    });
  }

  @override
  Future<Result<void>> guardarTipoDano(TipoDanoCatalogo tipo) {
    return _guardar(_colDanos, tipo.id, <String, Object?>{
      'nombre': tipo.nombre.trim(),
      'activo': tipo.activo,
      'orden': tipo.orden,
    });
  }

  @override
  Future<Result<void>> guardarZona(ZonaExteriorCatalogo zona) {
    return _guardar(_colZonas, zona.id, <String, Object?>{
      'nombre': zona.nombre.trim(),
      'activo': zona.activo,
      'orden': zona.orden,
    });
  }

  Future<Result<void>> _guardar(
    String coleccion,
    String id,
    Map<String, Object?> datos,
  ) async {
    try {
      await _col(coleccion).doc(id).set(<String, Object?>{
        ...datos,
        'actualizadoEn': FieldValue.serverTimestamp(),
        'actualizadoPor': _auth.currentUser?.uid,
      }, SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'No se pudo guardar el catálogo.');
    }
  }

  @override
  Future<Result<void>> sembrarIniciales() async {
    try {
      final WriteBatch batch = _firestore.batch();
      bool hayEscrituras = false;

      Future<bool> vacia(String coleccion) async {
        final QuerySnapshot<Map<String, dynamic>> snap = await _col(coleccion)
            .limit(1)
            .get();
        return snap.docs.isEmpty;
      }

      if (await vacia(_colEdificios)) {
        for (final EdificioCatalogo item in edificiosPorDefecto()) {
          batch.set(_col(_colEdificios).doc(item.id), <String, Object?>{
            'nombre': item.nombre,
            'pisos': item.pisos,
            'activo': item.activo,
            'orden': item.orden,
            'creadoEn': FieldValue.serverTimestamp(),
            'creadoPor': _auth.currentUser?.uid,
          });
          hayEscrituras = true;
        }
      }

      if (await vacia(_colSitios)) {
        for (final SitioReporteCatalogo item in sitiosPorDefecto()) {
          batch.set(_col(_colSitios).doc(item.id), <String, Object?>{
            'nombre': item.nombre,
            'slug': item.slug,
            'requiereEdificio': item.requiereEdificio,
            'requierePiso': item.requierePiso,
            'muestraReferencia': item.muestraReferencia,
            'referenciaObligatoria': item.referenciaObligatoria,
            'tipoEspecial': item.tipoEspecial,
            'activo': item.activo,
            'orden': item.orden,
            'creadoEn': FieldValue.serverTimestamp(),
            'creadoPor': _auth.currentUser?.uid,
          });
          hayEscrituras = true;
        }
      }

      if (await vacia(_colDanos)) {
        for (final TipoDanoCatalogo item in tiposDanoPorDefecto()) {
          batch.set(_col(_colDanos).doc(item.id), <String, Object?>{
            'nombre': item.nombre,
            'activo': item.activo,
            'orden': item.orden,
            'creadoEn': FieldValue.serverTimestamp(),
            'creadoPor': _auth.currentUser?.uid,
          });
          hayEscrituras = true;
        }
      }

      if (await vacia(_colZonas)) {
        for (final ZonaExteriorCatalogo item in zonasPorDefecto()) {
          batch.set(_col(_colZonas).doc(item.id), <String, Object?>{
            'nombre': item.nombre,
            'activo': item.activo,
            'orden': item.orden,
            'creadoEn': FieldValue.serverTimestamp(),
            'creadoPor': _auth.currentUser?.uid,
          });
          hayEscrituras = true;
        }
      }

      if (hayEscrituras) await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'No se pudieron crear los catálogos.');
    }
  }
}
