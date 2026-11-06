// Re-export del resultado canónico del dominio.
//
// Conversación T4: en disco convivían dos copias — `result.dart` (singular,
// recién introducida) y `results.dart` (plural, la original adoptada por la
// interface `ReporteRepository` de la fase 2/4 y por auth/tienda/sesión).
// Flutter exige un ÚNICO tipo `Result` para que el `@override` de
// `FirebaseReporteRepository.crear` sea válido (invalid_override), así que
// `result.dart` queda como re-export de `results.dart` y ambas rutas de
// import resuelven al MISMO tipo sellado.
export 'results.dart';
