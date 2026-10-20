import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'ayuda_ui.dart';

void main() {
  testWidgets('FEAT-002: los filtros se combinan con la búsqueda y se limpian',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NexaSoftApp());
    await esperar(tester);

    Future<void> elegir(String valorActual, String opcion) async {
      await tester.tap(desplegable(valorActual));
      await asentar(tester);
      await tester.tap(find.text(opcion).last);
      await asentar(tester);
    }

    final limpiar = find.widgetWithText(TextButton, 'Limpiar');
    bool limpiarActivo() => tester.widget<TextButton>(limpiar).onPressed != null;
    String texto() => tester.widget<TextField>(find.byType(TextField)).controller!.text;

    // Sin consulta: todos los registros y nada que limpiar.
    expect(find.text('10 registros'), findsOneWidget);
    expect(limpiarActivo(), isFalse);

    // Texto, estado y prioridad se aplican a la vez.
    await tester.enterText(find.byType(TextField), 'pantalla');
    await asentar(tester);
    expect(find.text('2 registros'), findsOneWidget);
    expect(limpiarActivo(), isTrue);

    await elegir('Todos', 'Pendiente');
    expect(find.text('2 registros'), findsOneWidget);

    await elegir('Todas', 'Alta');
    expect(find.text('0 registros'), findsOneWidget);
    expect(find.text('Ninguna incidencia cumple la búsqueda y los filtros activos.'),
        findsOneWidget);

    // El botón del mensaje restablece la consulta y los dos filtros.
    await tester.tap(find.text('Limpiar búsqueda y filtros'));
    await asentar(tester);
    expect(find.text('10 registros'), findsOneWidget);
    expect(texto(), isEmpty);
    expect(desplegable('Todos'), findsOneWidget);
    expect(desplegable('Todas'), findsOneWidget);
    expect(limpiarActivo(), isFalse);

    // Un filtro solo, y el botón Limpiar de la barra.
    await elegir('Todos', 'Resuelta');
    expect(find.text('3 registros'), findsOneWidget);
    await tester.tap(limpiar);
    await asentar(tester);
    expect(find.text('10 registros'), findsOneWidget);
    expect(desplegable('Todos'), findsOneWidget);
  });
}
