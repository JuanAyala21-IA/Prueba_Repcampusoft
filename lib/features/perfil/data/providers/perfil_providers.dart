import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/session_provider.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../auth/domain/usuario.dart';

/// Perfil del usuario autenticado, compartido por el dashboard y las pantallas
/// de perfil.
///
/// Se refresca cuando cambia el usuario de la sesión y cuando se invalida
/// explícitamente después de editar el perfil (así el nombre y los datos se
/// actualizan sin reiniciar la navegación).
final perfilUsuarioProvider = FutureProvider<Usuario?>((ref) async {
  final String? uid = ref.watch(sesionProvider.select((sesion) => sesion.uid));
  if (uid == null) return null;
  final repo = ref.read(authRepositoryProvider);
  return repo.obtenerPerfil(uid);
});
