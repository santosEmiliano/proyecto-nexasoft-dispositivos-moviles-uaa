import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El almacenamiento y los assets usan async real: se deja correr el reloj real
/// hasta que desaparece el indicador de carga.
Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await asentar(tester);
}

/// Deja terminar las transiciones y los menús desplegables.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Desplegable cuyo valor actual es [valorActual].
Finder desplegable(String valorActual) =>
    find.widgetWithText(DropdownButtonFormField<String>, valorActual);
