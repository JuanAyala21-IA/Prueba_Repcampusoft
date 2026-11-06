/// Catálogo local de edificios del campus (pantallas 8.png, 12.png).
abstract final class CatalogoEdificios {
  static const String a = 'Edificio A';
  static const String b = 'Edificio B';
  static const String c = 'Edificio C';
  static const String d = 'Edificio D';
  static const String e = 'Edificio E';
  static const String car = 'CAR';

  static const List<String> valores = [a, b, c, d, e, car];

  /// Solo hay salas de cómputo en los edificios A y B.
  static const List<String> salasComputo = [a, b];

  /// Solo hay cafetería en los edificios A, C y E.
  static const List<String> cafeterias = [a, c, e];
}
