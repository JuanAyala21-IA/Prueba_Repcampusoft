import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:repcampusoft/app.dart';

import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('La app arranca mostrando welcome', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const RepcampusoftApp(),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            (w.image as AssetImage).assetName ==
                'assets/images/logo_uts_blanco.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Sistema de reporte de daños'), findsOneWidget);
    expect(find.text('[Sistema de reporte de daños]'), findsNothing);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
  });
}
