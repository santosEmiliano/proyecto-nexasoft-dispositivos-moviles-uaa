import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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

Finder selectorPrioridad(String valorActual) =>
    find.widgetWithText(DropdownButtonFormField<String>, valorActual);

Finder enLista(String prioridad) =>
    find.textContaining('Prioridad $prioridad', findRichText: true);

void main() {
  testWidgets('FEAT-001: la prioridad se ve, se cambia y se elige al registrar',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NexaSoftApp());
    await esperar(tester);

    // Los registros de la semilla no traen prioridad y se muestran como Media.
    expect(enLista('Media'), findsWidgets);
    expect(enLista('Alta'), findsNothing);
    expect(enLista('Baja'), findsNothing);

    // Cambiar la prioridad desde el detalle.
    await tester.tap(find.text('Impresora del almacén no responde'));
    await asentar(tester);
    await tester.tap(selectorPrioridad('Media'));
    await asentar(tester);
    await tester.tap(find.text('Baja').last);
    await esperar(tester);
    await tester.pageBack();
    await asentar(tester);
    expect(enLista('Baja'), findsOneWidget);

    // Registrar una incidencia nueva con prioridad Alta.
    await tester.tap(find.text('Nueva incidencia'));
    await asentar(tester);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Incidencia de prueba');
    await tester.enterText(campos.at(1), 'Descripción de prueba');
    await tester.enterText(campos.at(2), 'Cliente ficticio');
    await tester.tap(selectorPrioridad('Media'));
    await asentar(tester);
    await tester.tap(find.text('Alta').last);
    await asentar(tester);
    await tester.tap(find.text('Registrar'));
    await esperar(tester);

    expect(find.text('Incidencia de prueba'), findsOneWidget);
    expect(enLista('Alta'), findsOneWidget);
    expect(enLista('Baja'), findsOneWidget);
  });
}
