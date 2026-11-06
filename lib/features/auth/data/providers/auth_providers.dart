import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/registro_intentado.dart';

/// Repositorio de autenticación inyectable (se sobreescribe en pruebas).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Registro pendiente de verificación de correo (§4): se conserva en memoria
/// mientras el usuario confirma el enlace y se limpia al crear el perfil o
/// al cerrar sesión.
class RegistroIntentadoController extends Notifier<RegistroIntentado?> {
  @override
  RegistroIntentado? build() => null;

  void guardar(RegistroIntentado intento) => state = intento;

  void limpiar() => state = null;
}

final registroIntentadoProvider =
    NotifierProvider<RegistroIntentadoController, RegistroIntentado?>(
      RegistroIntentadoController.new,
    );
