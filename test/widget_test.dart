import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:repcampusoft/app.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('La app arranca mostrando el login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RepcampusoftApp()));

    expect(find.text('REPCAMPUSOFT'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}