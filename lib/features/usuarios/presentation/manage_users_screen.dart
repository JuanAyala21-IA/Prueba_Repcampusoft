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

/// Panel del superadministrador para crear y deshabilitar cuentas de
/// estudiantes, administrativos y encargados de mantenimiento.
class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  /// Filtra por correo sin distinguir mayúsculas/minúsculas ni espacios.
  List<Usuario> _filtrar(List<Usuario> usuarios) {
    final String consulta = _busquedaCtrl.text.trim().toLowerCase();
    if (consulta.isEmpty) return usuarios;
    return usuarios
        .where((usuario) => usuario.correo.toLowerCase().contains(consulta))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Usuario>> usuariosAsync = ref.watch(
      usuariosGestionProvider,
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Gestión de usuarios',
                subtitulo: 'Crea y deshabilita cuentas',
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
              const SizedBox(height: 12),
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
                      return const _SinResultadosBusqueda();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Usuario usuario = filtrados[index];
                        return _UsuarioCard(
                          usuario: usuario,
                          onEliminar: usuario.esSuperadministrador
                              ? null
                              : () => _confirmarEliminacion(
                                  context,
                                  ref,
                                  usuario,
                                ),
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

  Future<void> _confirmarEliminacion(
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
          '(${usuario.correo})? No podrá volver a iniciar sesión.',
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
    switch (resultado) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta deshabilitada correctamente.')),
        );
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

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({required this.usuario, this.onEliminar});

  final Usuario usuario;
  final VoidCallback? onEliminar;

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
              color: AppColors.textPrimary,
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
                _RolChip(rol: usuario.rol),
              ],
            ),
          ),
          if (onEliminar != null)
            IconButton(
              tooltip: 'Deshabilitar cuenta',
              onPressed: onEliminar,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.estadoPendiente,
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

class _ListaUsuariosVacia extends StatelessWidget {
  const _ListaUsuariosVacia();

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
            Text(
              'No hay usuarios activos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera cuenta desde el botón superior.',
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
