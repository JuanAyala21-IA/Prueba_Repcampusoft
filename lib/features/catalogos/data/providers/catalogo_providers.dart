import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../catalogo_memoria_repository.dart';
import '../firebase_catalogo_repository.dart';
import '../../domain/catalogo_repository.dart';
import '../../domain/catalogos.dart';

/// Por defecto usa los catálogos locales en memoria. `main.dart` lo
/// sobreescribe con la implementación Firestore en producción.
final catalogoRepositoryProvider = Provider<CatalogoRepository>(
  (ref) => CatalogoMemoriaRepository(),
);

final edificiosCatalogoProvider = StreamProvider<List<EdificioCatalogo>>(
  (ref) => ref.watch(catalogoRepositoryProvider).watchEdificios(),
);

final sitiosCatalogoProvider = StreamProvider<List<SitioReporteCatalogo>>(
  (ref) => ref.watch(catalogoRepositoryProvider).watchSitios(),
);

final tiposDanoCatalogoProvider = StreamProvider<List<TipoDanoCatalogo>>(
  (ref) => ref.watch(catalogoRepositoryProvider).watchTiposDano(),
);

final zonasCatalogoProvider = StreamProvider<List<ZonaExteriorCatalogo>>(
  (ref) => ref.watch(catalogoRepositoryProvider).watchZonas(),
);

/// Overrides que se inyectan en el ProviderScope raíz (main.dart).
final List<Override> catalogosOverrides = <Override>[
  catalogoRepositoryProvider.overrideWith(
    (ref) => FirebaseCatalogoRepository(),
  ),
];
