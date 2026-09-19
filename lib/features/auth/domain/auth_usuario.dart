/// Vista de dominio del usuario de Firebase Authentication (protocolo mínimo
/// que necesita el controlador de sesión; desacopla la UI de `firebase_auth`).
abstract interface class AuthUsuario {
  String get uid;
  String? get email;
  bool get emailVerified;

  Future<void> reload();

  /// Fuerza el refresco del token para que `email_verified` refleje el
  /// último estado verificado por Firebase (se usa antes de crear `users/{uid}`).
  Future<void> refrescarToken();
}