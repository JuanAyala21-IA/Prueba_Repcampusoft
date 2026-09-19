/// Rol de usuario (dominio en español; valores de Firestore en minúsculas).
enum RolEnum {
  persona('persona'),
  administrativo('administrativo');

  const RolEnum(this.nombreFirestore);
  final String nombreFirestore;
}