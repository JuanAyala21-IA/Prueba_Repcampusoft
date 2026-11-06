import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_fallas_app_repository.dart';
import '../../domain/falla_app.dart';
import '../../domain/fallas_app_repository.dart';

/// Repositorio de fallas de la app (se sobreescribe en pruebas).
final fallasAppRepositoryProvider = Provider<FallasAppRepository>((ref) {
  return FirebaseFallasAppRepository();
});

/// Lista de fallas reportadas en tiempo real (solo administrativo).
final fallasAppListProvider = StreamProvider<List<FallaApp>>((ref) {
  return ref.watch(fallasAppRepositoryProvider).watchFallas();
});
