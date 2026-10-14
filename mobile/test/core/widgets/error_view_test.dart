import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpet_app/core/widgets/error_view.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('muestra el mensaje por defecto cuando no se pasa uno', (tester) async {
    await tester.pumpWidget(wrap(ErrorView(onRetry: () {})));

    expect(find.text('No se pudo cargar la información. Verifica tu conexión.'), findsOneWidget);
  });

  testWidgets('muestra un mensaje personalizado si se provee', (tester) async {
    await tester.pumpWidget(wrap(ErrorView(onRetry: () {}, message: 'Algo salió mal')));

    expect(find.text('Algo salió mal'), findsOneWidget);
  });

  testWidgets('llama a onRetry al tocar el botón Reintentar', (tester) async {
    var llamado = false;
    await tester.pumpWidget(wrap(ErrorView(onRetry: () => llamado = true)));

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(llamado, isTrue);
  });
}
