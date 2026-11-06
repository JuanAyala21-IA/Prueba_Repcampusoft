import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/results.dart';
import 'historial_entry.dart';
import 'reporte.dart';
import 'servicio_adjuntar_foto.dart';

/// Matriz de transiciones permitidas (§6.2 requisitos.md).
/// Claves = estado actual (valorFirestore ASCII), valores = estados destino permitidos.
const Map<String, Set<String>> transicionesPermitidas = {
  'Pendiente': {'En revision', 'Rechazado'},
  'En revision': {'En proceso', 'Rechazado'},
  'En proceso': {'Solucionado', 'Rechazado'},
};

/// Retorna los estados destino permitidos desde un [estadoActual], o conjunto vacío si es final.
Set<String> estadosDestinoPermitidos(String estadoActual) =>
    transicionesPermitidas[estadoActual] ?? const <String>{};

/// Persistencia de reportes en Firestore `reports/{reportId}` (arquitectura
/// §2.4). La implementación activa es la Fase 5 (batch atómico §6.2, pantalla
/// 8.png / RF-11, §2.6 de requisitos.md).
abstract interface class ReporteRepository {
  /// Persiste un reporte y devuelve su `reportId` como [Success].
  ///
  /// **Contrato (reglas `create` persona, firestore.rules §1.2/§2.4)**:
  /// - reporte: `uid==auth.uid`, `correoAutor==token.email`, `estado=='Pendiente'`.
  /// - historial `_inicial`: `estadoAnterior=='Pendiente'`, `estadoNuevo=='Pendiente'`,
  ///   `historialId==reportId+'_inicial'`, `!exists(report)` + `getAfter(report).uid`.
  /// - notificación `_creado`: `tipo=='reporte'`, `evento=='creado'`, `uidDestino==null`,
  ///   `destinoRol=='administrativo'`, `autorUid==auth.uid`, `notifId==reportId+'_'+evento`,
  ///   `!exists(report)` + `getAfter(report).estado`.
  ///
  /// Se envía en **un único WriteBatch atómico** (§6.2): si falla, ningún
  /// documento queda a medias. El `reportId` (determinista/reutilizable §6.1)
  /// es el ID de idempotencia ante reintentos.
  ///
  /// Devuelve [Failure] si: sin conexión (RNF-04), reglas rechazan la creación,
  /// o el batch falla. En caso de reintento tras `PERMISSION_DENIED` consulta
  /// `reports/{reportId}` para no duplicar (§6.2).
  Future<Result<String>> crear(BorradorReporte borrador);

  /// Stream de reportes del usuario actual, ordenados por `creadoEn` descendente.
  Stream<List<Reporte>> watchMisReportes();

  /// Stream de un reporte por ID en tiempo real (útil para ver actualizaciones
  /// de estado realizadas por el admin).
  Stream<Reporte?> watchReporteById(String reportId);

  /// Stream de entradas de historial `reports/{reportId}/historial`,
  /// ordenadas por fecha ascendente.
  Stream<List<HistorialEntry>> watchHistorial(String reportId);

  /// Stream de TODOS los reportes (admin), ordenados por `creadoEn` descendente.
  /// Filtros opcionales: [filtroEstado] (ej. 'Pendiente', 'En revision', 'En proceso',
  /// 'Solucionado', 'Rechazado') y [filtroEdificio] (ej. 'Edificio A').
  Stream<List<Reporte>> watchTodosLosReportes({
    String? filtroEstado,
    String? filtroEdificio,
  });

  /// Cambia el estado de un reporte (admin) con validación de transiciones
  /// permitidas (§6.2 requisitos.md):
  /// - Pendiente → En revision | Rechazado
  /// - En revision → En proceso | Rechazado
  /// - En proceso → Solucionado | Rechazado
  /// - Solucionado / Rechazado: no transicionan (estados finales).
  /// Exige [observacion] si [estadoNuevo] == 'Rechazado'.
  /// [evidenciaBase64] es la foto que prueba la solución: **obligatoria** al
  /// pasar a `Solucionado`, se guarda en `media/solucion`.
  /// Devuelve [Failure] si la transición no es válida (validación cliente, sin tocar Firestore).
  Future<Result<void>> cambiarEstado({
    required String reportId,
    required String estadoNuevo,
    String? observacion,
    String? evidenciaBase64,
  }) {
    // Nota: el estado actual se leerá en la implementación (Firestore) antes de escribir.
    // Aquí validamos solo que el estadoNuevo sea un estado conocido y exigimos observación
    // para Rechazado. La validación estricta de estadoActual → estadoNuevo se hará en la
    // implementación con runTransaction.
    const estadosValidos = [
      'Pendiente',
      'En revision',
      'En proceso',
      'Solucionado',
      'Rechazado',
    ];
    if (!estadosValidos.contains(estadoNuevo)) {
      return Future.value(Failure('Estado inválido: $estadoNuevo'));
    }
    if (estadoNuevo == 'Rechazado' &&
        (observacion == null || observacion.trim().isEmpty)) {
      return Future.value(Failure('Observación obligatoria al rechazar'));
    }
    // La validación de transición concreta (estadoActual → estadoNuevo) requiere
    // leer el doc; se hace en la implementación Firebase con runTransaction.
    return Future.value(Failure('Implementar en Firebase repo'));
  }

  /// Asigna el reporte al encargado de mantenimiento actual. Falla si otro
  /// compañero ya lo tomó (`already-assigned`) o si el reporte está cerrado.
  Future<Result<void>> tomarReporte({required String reportId}) {
    return Future.value(Failure('Implementar en Firebase repo'));
  }
}

/// Proveedor del repositorio. La Fase 5 lo implementa en
/// `data/firebase_reporte_repository.dart` y se inyecta vía
/// `data/providers/reporte_providers.dart` (patrón Fases 1-4).
final reporteRepositoryProvider = Provider<ReporteRepository>(
  (ref) => throw UnimplementedError(
    'Se inyecta en data/providers/reporte_providers.dart',
  ),
);

/// Sonda de conectividad del dispositivo (RNF-04/RNF-05, pantallas 1/6/7/8/
/// 10). Proveedor de la abstracción para que la pantalla 8 avise y ofrezca
/// enviar sin foto cuando no hay conexión.
final sondaConectividadProvider = Provider<SondaConectividad>(
  (ref) => throw UnimplementedError(
    'Se inyecta en data/providers/reporte_providers.dart',
  ),
);
