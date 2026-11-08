import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/catalogos/data/firebase_catalogo_repository.dart';
import 'package:repcampusoft/features/catalogos/domain/catalogos.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseCatalogoRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseCatalogoRepository(
      firestore: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'admin-uid', email: 'admin@uts.edu.co'),
      ),
    );
  });

  test('sembrarIniciales crea los catálogos y es idempotente', () async {
    await repository.sembrarIniciales();
    await repository.sembrarIniciales();

    final edificios = await repository.watchEdificios().first;
    final sitios = await repository.watchSitios().first;
    final danos = await repository.watchTiposDano().first;
    final zonas = await repository.watchZonas().first;

    expect(edificios.length, 6);
    expect(sitios.any((s) => s.nombre == 'Aula / salón'), isTrue);
    expect(danos.any((d) => d.nombre == 'Silla dañada'), isTrue);
    expect(zonas.any((z) => z.nombre == 'Jardines'), isTrue);
  });

  test('guardarEdificio y guardarTipoDano actualizan los streams', () async {
    await repository.sembrarIniciales();
    await repository.guardarEdificio(
      const EdificioCatalogo(
        id: 'edificio_f',
        nombre: 'Edificio F',
        pisos: ['Piso 1', 'Piso 2'],
        orden: 99,
      ),
    );
    await repository.guardarTipoDano(
      const TipoDanoCatalogo(
        id: 'vidrio_roto',
        nombre: 'Vidrio roto',
        orden: 99,
      ),
    );

    final edificios = await repository.watchEdificios().first;
    final danos = await repository.watchTiposDano().first;

    expect(edificios.any((e) => e.id == 'edificio_f'), isTrue);
    expect(danos.any((d) => d.id == 'vidrio_roto'), isTrue);
  });
}
