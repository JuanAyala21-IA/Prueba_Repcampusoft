import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../../../core/utils/results.dart';
import '../../auth/data/firebase_auth_messages.dart';
import '../../auth/domain/rol_enum.dart';
import '../../auth/domain/usuario.dart';
import '../domain/usuario_repository.dart';

/// Gestión de cuentas sobre Firebase Auth + Firestore.
///
/// Firebase no permite que un cliente cree cuentas de otros usuarios con el
/// SDK normal, así que se usa una instancia secundaria de Firebase Auth: se
/// crea la cuenta allí, se escribe el perfil desde la sesión del
/// superadministrador y se cierra la instancia secundaria. La eliminación es
/// lógica (`activo: false`): el SDK cliente tampoco puede borrar cuentas de
/// Auth ajenas sin Admin SDK/Cloud Functions.
class FirebaseUsuarioRepository implements UsuarioRepository {
  FirebaseUsuarioRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  @override
  Stream<List<Usuario>> watchUsuarios() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final usuarios =
          snapshot.docs
              .map(_mapUsuario)
              .where((usuario) => usuario.activo)
              .toList()
            ..sort(
              (a, b) =>
                  a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
            );
      return usuarios;
    });
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
    if (!RolEnum.rolesGestionables.contains(rol)) {
      return const Failure(
        'El rol seleccionado no se puede crear desde la app.',
      );
    }

    final String correoNormalizado = correo.trim().toLowerCase();
    final String nombreNormalizado = nombre.trim();
    if (nombreNormalizado.isEmpty) {
      return const Failure('Ingresa el nombre completo.');
    }
    if (contrasena.length < 6) {
      return const Failure('La contraseña debe tener al menos 6 caracteres.');
    }

    final String nombreApp =
        'repcampusoft-usuarios-${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? appSecundaria;
    fb.FirebaseAuth? authSecundaria;
    fb.User? usuarioCreado;

    try {
      appSecundaria = await Firebase.initializeApp(
        name: nombreApp,
        options: Firebase.app().options,
      );
      authSecundaria = fb.FirebaseAuth.instanceFor(app: appSecundaria);
      final fb.UserCredential credencial = await authSecundaria
          .createUserWithEmailAndPassword(
            email: correoNormalizado,
            password: contrasena,
          );
      usuarioCreado = credencial.user;
      if (usuarioCreado == null) {
        return const Failure('No se pudo crear la cuenta del usuario.');
      }

      // El nuevo usuario debe confirmar su correo antes de entrar al sistema.
      try {
        await usuarioCreado.sendEmailVerification();
      } catch (_) {
        // La cuenta ya existe; el usuario puede reenviar la verificación al
        // iniciar sesión.
      }

      final Map<String, dynamic> datos = {
        'nombre': nombreNormalizado,
        'correo': correoNormalizado,
        'rol': rol.nombreFirestore,
        'activo': true,
        if (cargo != null && cargo.trim().isNotEmpty) 'cargo': cargo.trim(),
        if (dependencia != null && dependencia.trim().isNotEmpty)
          'dependencia': dependencia.trim(),
        if (telefono != null && telefono.trim().isNotEmpty)
          'telefono': telefono.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(usuarioCreado.uid).set(datos);

      return Success(
        Usuario(
          uid: usuarioCreado.uid,
          nombre: nombreNormalizado,
          correo: correoNormalizado,
          rol: rol,
          cargo: cargo?.trim().isEmpty ?? true ? null : cargo!.trim(),
          dependencia: dependencia?.trim().isEmpty ?? true
              ? null
              : dependencia!.trim(),
          telefono: telefono?.trim().isEmpty ?? true ? null : telefono!.trim(),
        ),
      );
    } on FirebaseException catch (error) {
      // Si Auth se creó pero Firestore falló, se revierte la cuenta para no
      // dejar un usuario huérfano sin perfil.
      await _borrarCuentaSecundaria(usuarioCreado);
      return Failure(mensajeFirebase(error));
    } catch (error) {
      await _borrarCuentaSecundaria(usuarioCreado);
      return Failure(mensajeFirebase(error));
    } finally {
      try {
        await authSecundaria?.signOut();
      } catch (_) {}
      try {
        await appSecundaria?.delete();
      } catch (_) {}
    }
  }

  Future<void> _borrarCuentaSecundaria(fb.User? usuario) async {
    try {
      await usuario?.delete();
    } catch (_) {
      // Si la eliminación falla, el perfil no se escribió; la cuenta queda
      // huérfana y el gate la trata como "completar perfil".
    }
  }

  @override
  Future<Result<void>> eliminarUsuario(Usuario usuario) async {
    if (usuario.rol == RolEnum.superadministrador) {
      return const Failure(
        'El superadministrador no se puede eliminar desde la app.',
      );
    }
    if (_auth.currentUser?.uid == usuario.uid) {
      return const Failure('No puedes eliminar tu propia cuenta.');
    }
    try {
      await _firestore.collection('users').doc(usuario.uid).update({
        'activo': false,
        'eliminadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } on FirebaseException catch (error) {
      return Failure(mensajeFirebase(error));
    }
  }

  Usuario _mapUsuario(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Usuario(
      uid: doc.id,
      nombre: data['nombre'] as String? ?? '',
      correo: data['correo'] as String? ?? '',
      rol: RolEnum.desdeFirestore(data['rol'] as String?),
      cargo: data['cargo'] as String?,
      dependencia: data['dependencia'] as String?,
      telefono: data['telefono'] as String?,
      activo: data['activo'] as bool? ?? true,
    );
  }
}
