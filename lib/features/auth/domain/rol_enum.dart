/// Rol de usuario (dominio en español; valores de Firestore en minúsculas).
enum RolEnum {
  persona('persona', 'Persona'),
  administrativo('administrativo', 'Administrativo');

  const RolEnum(this.nombreFirestore, this.etiqueta);
  final String nombreFirestore;
  final String etiqueta;
}