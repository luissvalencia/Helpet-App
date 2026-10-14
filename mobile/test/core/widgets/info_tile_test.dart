import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpet_app/core/widgets/info_tile.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('muestra el label y el valor recibidos', (tester) async {
    await tester.pumpWidget(
      wrap(const InfoTile(icono: Icons.pets, label: 'Especie', valor: 'Perro')),
    );

    expect(find.text('Especie'), findsOneWidget);
    expect(find.text('Perro'), findsOneWidget);
  });

  testWidgets('muestra un guion largo cuando el valor está vacío', (tester) async {
    await tester.pumpWidget(
      wrap(const InfoTile(icono: Icons.pets, label: 'Raza', valor: '')),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
