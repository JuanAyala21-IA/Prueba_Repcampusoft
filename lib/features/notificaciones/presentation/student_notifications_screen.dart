import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../shared/widgets/bell_badge.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/notification_card.dart';
import '../../../shared/widgets/uts_header.dart';
import '../domain/notificacion.dart';
import '../data/providers/notificacion_providers.dart';

/// Pantalla 11: Notificaciones Estudiante (stream real desde Firestore).
class StudentNotificationsScreen extends ConsumerWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Notificacion>> asyncNotificaciones = ref.watch(
      notificacionesEstudianteProvider,
    );
    final AsyncValue<int> asyncContador = ref.watch(
      contadorNoLeidasEstudianteProvider,
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: asyncNotificaciones.when(
            loading: () => const _CargandoNotificaciones(),
            error: (error, _) => _ErrorCarga(mensaje: error.toString()),
            data: (notificaciones) {
              final int conteoNoLeidas = asyncContador.maybeWhen(
                data: (value) => value,
                orElse: () => 0,
              );

              return Column(
                children: [
                  UtsHeader(
                    titulo: 'Notificaciones',
                    mostrarLogo: false,
                    accion: BellBadge(conteo: conteoNoLeidas),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: notificaciones.isEmpty
                        ? const _ListaVacia()
                        : _ListaNotificaciones(notificaciones: notificaciones),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CargandoNotificaciones extends StatelessWidget {
  const _CargandoNotificaciones();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Notificaciones', mostrarLogo: false),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Notificaciones', mostrarLogo: false),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudieron cargar las notificaciones',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mensaje,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando tengas actualizaciones en tus reportes,\naparecerán aquí.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaNotificaciones extends ConsumerWidget {
  const _ListaNotificaciones({required this.notificaciones});

  final List<Notificacion> notificaciones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(notificaciones.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 12);
          }
          final notificacion = notificaciones[index ~/ 2];
          return _NotificacionItem(notificacion: notificacion);
        }),
      ),
    );
  }
}

class _NotificacionItem extends ConsumerWidget {
  const _NotificacionItem({required this.notificacion});

  final Notificacion notificacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationCard(
      titulo: notificacion.titulo,
      mensaje: notificacion.mensaje,
      fecha: _formatFecha(notificacion.creadoEn),
      icono: _iconoPorEvento(notificacion.evento, notificacion.tipo),
      leida: notificacion.leida,
      onTap: () async {
        if (notificacion.reportId != null) {
          await ref
              .read(notificacionRepositoryProvider)
              .marcarLeida(ref.read(sesionProvider).uid!, notificacion.id);
          if (context.mounted) {
            context.push(
              '${AppRoutes.detalleReporte}/${notificacion.reportId}',
            );
          }
        }
      },
    );
  }

  String _formatFecha(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDate = DateTime(date.year, date.month, date.day);

    if (notifDate == today) {
      return 'Hoy, ${_formatHour(date)}';
    } else if (notifDate == yesterday) {
      return 'Ayer, ${_formatHour(date)}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatHour(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'p.m.' : 'a.m.';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  IconData _iconoPorEvento(NotificacionEvento? evento, NotificacionTipo tipo) {
    if (evento != null) {
      switch (evento) {
        case NotificacionEvento.creado:
          return Icons.description_outlined;
        case NotificacionEvento.enRevision:
          return Icons.search_rounded;
        case NotificacionEvento.enProceso:
          return Icons.build_outlined;
        case NotificacionEvento.solucionado:
          return Icons.check_circle_outline;
        case NotificacionEvento.rechazado:
          return Icons.warning_amber_rounded;
      }
    }
    switch (tipo) {
      case NotificacionTipo.administrativo:
        return Icons.campaign_outlined;
      case NotificacionTipo.sistema:
        return Icons.info_outline;
      case NotificacionTipo.reporte:
        return Icons.notifications_outlined;
    }
  }
}
