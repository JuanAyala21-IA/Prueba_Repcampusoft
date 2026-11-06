/// Adjunta la foto de evidencia a `reports/{reportId}/media/foto` (§2.5/§8.1).
///
/// **Importante (contrato de reglas §8.1)**: `media/{mediaId}.create` persona usa
/// `get(reportDoc(reportId)).data.uid == request.auth.uid` — es decir, `get()`
/// (NO `getAfter`). Por eso la foto **no** puede ir dentro del WriteBatch del
/// reporte: debe subirse **después** del commit del batch (§6.2/§8.1, post-batch).
///
/// Implementación activa: `FotoBase64Repository` (comprime ~500 KB y persiste
/// Base64 en `media/foto`; RNF-02, §2.5).
abstract interface class ServicioAdjuntarFoto {
  /// Persiste `foto` en `reports/{reportId}/media/foto` (ID fijo `foto`).
  ///
  /// Devuelve `true` si la foto se guardó correctamente. Antes de devolver
  /// `false` intenta la consulta media; si la foto ya existe se reporta
  /// como éxito (idempotencia de reintentos §6.2).
  Future<bool> adjuntar({
    required String reportId,
    required String base64,
    required int tamanoBytes,
    required String mimeType,
  });
}

/// Sonda de conectividad para RNF-04 (pantallas 1, 6, 7, 8).
///
/// Voice-pattern de Fase 1-4: la UI no depende de `connectivity_plus`
/// directamente; la importa esta abstracción (data).
abstract interface class SondaConectividad {
  /// `true` si hay conexión activa a Internet (RNF-04/RNF-05).
  ///
  /// En la pantalla 8 se usa para: (1) avisar al usuario si no hay conexión y
  /// (2) subir el reporte SIN foto (cuando no hay conexión no se adjuntan
  /// evidencias, §8.1: la foto exige conexión activa).
  Future<bool> hayConexion();
}
