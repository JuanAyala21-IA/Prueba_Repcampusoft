import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../auth/domain/rol_enum.dart';
import '../../auth/domain/usuario.dart';
import '../data/providers/usuario_providers.dart';

/// Filtro de la lista por estado de la cuenta.
enum _FiltroUsuarios { todos, activos, deshabilitados }

/// Panel del superadministrador para crear, deshabilitar y reactivar cuentas de
/// estudiantes, administrativos y encargados de mantenimiento.
class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final TextEditingController _busquedaCtrl = TextEditingController();
  _FiltroUsuarios _filtro = _FiltroUsuarios.todos;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  /// Aplica el filtro de estado y la búsqueda por correo (sin distinguir
  /// mayúsculas/minúsculas ni espacios).
  List<Usuario> _filtrar(List<Usuario> usuarios) {
    final List<Usuario> porEstado = switch (_filtro) {
      _FiltroUsuarios.todos => usuarios,
      _FiltroUsuarios.activos =>
        usuarios.where((usuario) => usuario.activo).toList(),
      _FiltroUsuarios.deshabilitados =>
        usuarios.where((usuario) => !usuario.activo).toList(),
    };
    final String consulta = _busquedaCtrl.text.trim().toLowerCase();
    if (consulta.isEmpty) return porEstado;
    return porEstado
        .where((usuario) => usuario.correo.toLowerCase().contains(consulta))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Usuario>> usuariosAsync = ref.watch(
      usuariosGestionProvider,
    );
    final List<Usuario> usuarios =
        usuariosAsync.value ?? const <Usuario>[];

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Gestión de usuarios',
                subtitulo: 'Consulta, deshabilita y reactiva cuentas',
                mostrarLogo: false,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.crearUsuario),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Crear usuario'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _busquedaCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por correo',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busquedaCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _busquedaCtrl.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _FiltroChip(
                        etiqueta: 'Todos',
                        cantidad: usuarios.length,
                        seleccionado: _filtro == _FiltroUsuarios.todos,
                        onSelected: () =>
                            setState(() => _filtro = _FiltroUsuarios.todos),
                      ),
                      _FiltroChip(
                        etiqueta: 'Activos',
                        cantidad: usuarios
                            .where((usuario) => usuario.activo)
                            .length,
                        seleccionado: _filtro == _FiltroUsuarios.activos,
                        onSelected: () =>
                            setState(() => _filtro = _FiltroUsuarios.activos),
                      ),
                      _FiltroChip(
                        etiqueta: 'Deshabilitados',
                        cantidad: usuarios
                            .where((usuario) => !usuario.activo)
                            .length,
                        seleccionado: _filtro == _FiltroUsuarios.deshabilitados,
                        onSelected: () => setState(
                          () => _filtro = _FiltroUsuarios.deshabilitados,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: usuariosAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      _ErrorUsuarios(mensaje: error.toString()),
                  data: (usuarios) {
                    if (usuarios.isEmpty) {
                      return const _ListaUsuariosVacia();
                    }
                    final List<Usuario> filtrados = _filtrar(usuarios);
                    if (filtrados.isEmpty) {
                      if (_busquedaCtrl.text.trim().isNotEmpty) {
                        return const _SinResultadosBusqueda();
                      }
                      return _ListaUsuariosVacia(
                        mensaje: _filtro == _FiltroUsuarios.deshabilitados
                            ? 'No hay cuentas deshabilitadas.'
                            : 'No hay cuentas activas.',
                        detalle: 'Cambia el filtro para ver otras cuentas.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Usuario usuario = filtrados[index];
                        return _UsuarioCard(
                          usuario: usuario,
                          onDeshabilitar:
                              usuario.activo && !usuario.esSuperadministrador
                              ? () => _confirmarDeshabilitacion(
                                  context,
                                  ref,
                                  usuario,
                                )
                              : null,
                          onReactivar:
                              !usuario.activo && !usuario.esSuperadministrador
                              ? () => _confirmarReactivacion(
                                  context,
                                  ref,
                                  usuario,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarDeshabilitacion(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deshabilitar cuenta'),
        content: Text(
          '¿Deseas deshabilitar la cuenta de ${usuario.nombre} '
          '(${usuario.correo})? No podrá iniciar sesión hasta que la reactives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Deshabilitar',
              style: TextStyle(color: AppColors.estadoPendiente),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final Result<void> resultado = await ref
        .read(usuarioRepositoryProvider)
        .eliminarUsuario(usuario);
    if (!context.mounted) return;
    _mostrarResultado(
      context,
      resultado,
      exito: 'Cuenta deshabilitada correctamente.',
    );
  }

  Future<void> _confirmarReactivacion(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reactivar cuenta'),
        content: Text(
          '¿Deseas reactivar la cuenta de ${usuario.nombre} '
          '(${usuario.correo})? Podrá volver a iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final Result<void> resultado = await ref
        .read(usuarioRepositoryProvider)
        .reactivarUsuario(usuario);
    if (!context.mounted) return;
    _mostrarResultado(
      context,
      resultado,
      exito: 'Cuenta reactivada correctamente.',
    );
  }

  void _mostrarResultado(
    BuildContext context,
    Result<void> resultado, {
    required String exito,
  }) {
    switch (resultado) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exito)));
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.message),
            backgroundColor: AppColors.estadoPendiente,
          ),
        );
    }
  }
}

/// Chip de filtro con el número de cuentas que representa.
class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.etiqueta,
    required this.cantidad,
    required this.seleccionado,
    required this.onSelected,
  });

  final String etiqueta;
  final int cantidad;
  final bool seleccionado;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$etiqueta ($cantidad)'),
      selected: seleccionado,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.utsGreen,
      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      side: const BorderSide(color: AppColors.divider),
      backgroundColor: AppColors.background,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({
    required this.usuario,
    this.onDeshabilitar,
    this.onReactivar,
  });

  final Usuario usuario;
  final VoidCallback? onDeshabilitar;
  final VoidCallback? onReactivar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surface,
            child: Icon(
              _iconoPorRol(usuario.rol),
              color: usuario.activo ? AppColors.textPrimary : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre.isEmpty ? 'Sin nombre' : usuario.nombre,
                  style: AppTypography.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(usuario.correo, style: AppTypography.textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _RolChip(rol: usuario.rol),
                    _EstadoChip(activo: usuario.activo),
                  ],
                ),
              ],
            ),
          ),
          if (onDeshabilitar != null)
            IconButton(
              tooltip: 'Deshabilitar cuenta',
              onPressed: onDeshabilitar,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.estadoPendiente,
              ),
            ),
          if (onReactivar != null)
            IconButton(
              tooltip: 'Reactivar cuenta',
              onPressed: onReactivar,
              icon: const Icon(
                Icons.how_to_reg_outlined,
                color: AppColors.welcomeBackground,
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconoPorRol(RolEnum rol) {
    return switch (rol) {
      RolEnum.persona => Icons.school_outlined,
      RolEnum.administrativo => Icons.admin_panel_settings_outlined,
      RolEnum.mantenimiento => Icons.build_outlined,
      RolEnum.superadministrador => Icons.verified_user_outlined,
    };
  }
}

class _RolChip extends StatelessWidget {
  const _RolChip({required this.rol});

  final RolEnum rol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        rol.etiqueta,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Etiqueta Activo/Deshabilitado de la cuenta.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? AppColors.utsGreen : AppColors.grisOscuro,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'Activo' : 'Deshabilitado',
        style: AppTypography.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: activo ? AppColors.textPrimary : Colors.white,
        ),
      ),
    );
  }
}

class _ListaUsuariosVacia extends StatelessWidget {
  const _ListaUsuariosVacia({
    this.mensaje = 'No hay usuarios registrados',
    this.detalle = 'Crea la primera cuenta desde el botón superior.',
  });

  final String mensaje;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(mensaje, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              detalle,
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinResultadosBusqueda extends StatelessWidget {
  const _SinResultadosBusqueda();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay usuarios con ese correo.',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorUsuarios extends StatelessWidget {
  const _ErrorUsuarios({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los usuarios',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: AppTypography.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
