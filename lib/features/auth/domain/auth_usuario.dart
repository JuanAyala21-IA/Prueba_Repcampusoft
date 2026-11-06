/// Vista de dominio del usuario de Firebase Authentication (protocolo mínimo
/// que necesita el controlador de sesión; desacopla la UI de `firebase_auth`).
abstract interface class AuthUsuario {
  String get uid;
  String? get email;
  bool get emailVerified;

  /// Nombre que reporta el proveedor de identidad (Google lo entrega en
  /// `displayName`; con correo/contraseña puede ser `null`).
  String? get displayName;

  /// `true` si la sesión se autenticó con Google.
  bool get autenticadoConGoogle;

  /// Correo confiable para crear `users/{uid}`:
  /// - correo/contraseña: exige `emailVerified`.
  /// - Google: la identidad la valida Google, aunque Firebase dejara
  ///   `emailVerified` en `false` para este proveedor.
  bool get correoConfiable;

  Future<void> reload();

  /// Fuerza el refresco del token para que `email_verified` refleje el
  /// último estado verificado por Firebase (se usa antes de crear `users/{uid}`).
  Future<void> refrescarToken();
}
