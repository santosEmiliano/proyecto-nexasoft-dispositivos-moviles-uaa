import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Crea un gestor nuevo y lo inicia, sería lo mismo que abrir la app de cero.
Future<GestorIncidencias> abrirApp() async {
  final gestor = GestorIncidencias();
  await gestor.iniciar();
  return gestor;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Almacenamiento vacío en cada prueba, ya que la app arranca con el JSON semilla.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('BUG-001: el cambio de estado se conserva', () {
    test('el nuevo estado sigue ahí tras reiniciar la app', () async {
      final sesion1 = await abrirApp();
      expect(sesion1.porId('INC-101')!.estado, 'Pendiente');

      await sesion1.cambiarEstado('INC-101', 'Resuelta');
      expect(sesion1.porId('INC-101')!.estado, 'Resuelta');

      final sesion2 = await abrirApp();
      expect(sesion2.porId('INC-101')!.estado, 'Resuelta');
    });

    test('cambiar una incidencia no altera las demás', () async {
      final sesion1 = await abrirApp();
      final antes = {for (final x in sesion1.incidencias) x.id: x.estado};

      await sesion1.cambiarEstado('INC-101', 'Resuelta');

      final sesion2 = await abrirApp();
      expect(sesion2.incidencias.length, antes.length);
      for (final x in sesion2.incidencias) {
        final esperado = x.id == 'INC-101' ? 'Resuelta' : antes[x.id];
        expect(x.estado, esperado, reason: 'estado de ${x.id}');
      }
    });

    test('una incidencia registrada sigue existiendo tras reiniciar', () async {
      final sesion1 = await abrirApp();
      await sesion1.crear(
          'Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes');
      final idNueva = sesion1.incidencias.first.id;

      final sesion2 = await abrirApp();
      expect(sesion2.porId(idNueva), isNotNull);
      expect(sesion2.incidencias.length, 11);
    });
  });
}
