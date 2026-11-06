import 'dart:async';

import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/usuarios/domain/usuario_repository.dart';

/// Llamada registrada a [FakeUsuarioRepository.crearUsuario].
class CreacionUsuarioRegistrada {
  CreacionUsuarioRegistrada({
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
    this.cargo,
    this.dependencia,
    this.telefono,
  });

  final String nombre;
  final String correo;
  final String contrasena;
  final RolEnum rol;
  final String? cargo;
  final String? dependencia;
  final String? telefono;
}

/// Repositorio de gestión de usuarios en memoria para pruebas de widgets.
class FakeUsuarioRepository implements UsuarioRepository {
  FakeUsuarioRepository({
    List<Usuario> usuarios = const <Usuario>[],
    this.resultadoCreacion,
    this.resultadoEliminacion = const Success<void>(null),
  }) : _usuarios = List<Usuario>.of(usuarios);

  final StreamController<List<Usuario>> _controller =
      StreamController<List<Usuario>>.broadcast();

  List<Usuario> _usuarios;
  Object? _error;

  /// Si es `null`, la creación devuelve un [Success] con el usuario creado.
  Result<Usuario>? resultadoCreacion;
  Result<void> resultadoEliminacion;

  final List<CreacionUsuarioRegistrada> creaciones =
      <CreacionUsuarioRegistrada>[];
  final List<Usuario> eliminados = <Usuario>[];

  void emitir(List<Usuario> usuarios) {
    _usuarios = List<Usuario>.of(usuarios);
    _controller.add(_usuarios);
  }

  void emitirError(Object error) {
    _error = error;
    _controller.addError(error);
  }

  Future<void> cerrar() => _controller.close();

  @override
  Stream<List<Usuario>> watchUsuarios() async* {
    final Object? error = _error;
    if (error != null) {
      throw error;
    }
    yield _usuarios;
    yield* _controller.stream;
  }

  @override
  Future<Result<Usuario>> crearUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required RolEnum rol,
    String? cargo,
    String? dependencia,
    String? telefono,
  }) async {
    creaciones.add(
      CreacionUsuarioRegistrada(
        nombre: nombre,
        correo: correo,
        contrasena: contrasena,
        rol: rol,
        cargo: cargo,
        dependencia: dependencia,
        telefono: telefono,
      ),
    );
    final Result<Usuario>? resultado = resultadoCreacion;
    if (resultado != null) return resultado;
    return Success(
      Usuario(
        uid: 'uid-${correo.trim().toLowerCase()}',
        nombre: nombre.trim(),
        correo: correo.trim().toLowerCase(),
        rol: rol,
        cargo: cargo,
        dependencia: dependencia,
        telefono: telefono,
      ),
    );
  }

  @override
  Future<Result<void>> eliminarUsuario(Usuario usuario) async {
    eliminados.add(usuario);
    return resultadoEliminacion;
  }
}
