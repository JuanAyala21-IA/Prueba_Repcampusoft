import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usuario_repository.dart';
import '../../../auth/domain/usuario.dart';
import '../firebase_usuario_repository.dart';

/// Repositorio de gestión de cuentas (se sobreescribe en pruebas).
final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return FirebaseUsuarioRepository();
});

/// Usuarios activos en tiempo real. Solo el superadministrador consume este
/// provider; el guard del router impide que otros roles abran la pantalla.
final usuariosGestionProvider = StreamProvider<List<Usuario>>((ref) {
  return ref.watch(usuarioRepositoryProvider).watchUsuarios();
});
