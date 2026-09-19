import 'package:firebase_auth/firebase_auth.dart';

/// Traduce errores de Firebase (auth y firestore) a mensajes claros en
/// español para el usuario (CA-01.3, CA-02.4, RF-10).
String mensajeFirebase(Object error) {
  if (error is FirebaseAuthException) return _mensajeAuth(error);
  if (error is FirebaseException) return _mensajeFirestore(error);
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

String _mensajeAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'user-disabled':
      return 'Tu cuenta está deshabilitada. Contacta a la institución.';
    case 'too-many-requests':
      return 'Demasiados intentos fallidos. Espera unos minutos y vuelve a intentarlo.';
    case 'operation-not-allowed':
      return 'El acceso con correo y contraseña no está habilitado en este momento.';
    case 'email-already-in-use':
      return 'Este correo ya está registrado. Prueba iniciando sesión.';
    case 'weak-password':
      return 'La contraseña debe tener al menos 6 caracteres.';
    case 'network-request-failed':
    case 'timeout':
      return 'Sin conexión a internet. Verifica tu red e inténtalo de nuevo.';
    case 'missing-password':
      return 'Ingresa tu contraseña.';
    case 'missing-email':
      return 'Ingresa tu correo institucional.';
    case 'quota-exceeded':
      return 'El servicio está saturado. Inténtalo más tarde.';
    default:
      return 'Ocurrió un error inesperado (${e.code}). Inténtalo de nuevo.';
  }
}

String _mensajeFirestore(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return 'No tienes permiso para realizar esta acción.';
    case 'unavailable':
    case 'aborted':
    case 'failed-precondition':
      return 'El servicio está ocupado. Inténtalo de nuevo.';
    default:
      return 'Ocurrió un error inesperado (${e.code}). Inténtalo de nuevo.';
  }
}