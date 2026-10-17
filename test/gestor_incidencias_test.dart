import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
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

  group('BUG-002: la búsqueda encuentra los registros existentes', () {
    late GestorIncidencias gestor;
    Set<String> ids(String consulta) =>
        gestor.buscar(consulta).map((x) => x.id).toSet();

    setUp(() async {
      gestor = await abrirApp();
    });

    test('ignora mayúsculas y minúsculas', () {
      expect(ids('wifi'), {'INC-102'});
      expect(ids('WiFi'), {'INC-102'});
      expect(ids('WIFI'), {'INC-102'});
    });

    test('busca también en la descripción', () {
      // «túnel» solo aparece en la descripción de INC-106 (VPN).
      expect(ids('túnel'), {'INC-106'});
      expect(ids('TÚNEL'), {'INC-106'});
    });

    test('ignora los acentos, escriba o no el acento el usuario', () {
      expect(ids('tunel'), {'INC-106'});
      expect(ids('TUNEL'), {'INC-106'});
      expect(ids('túnel'), {'INC-106'});
      // Con acento en el texto guardado y sin acento en la consulta, y al revés.
      expect(ids('configuracion'), {'INC-106'});
      expect(ids('recepcion'), {'INC-102', 'INC-107'});
    });

    test('combina coincidencias de título y de descripción', () {
      // "recepción", porque es título de INC-102 y descripción de INC-107.
      expect(ids('recepción'), {'INC-102', 'INC-107'});
    });

    test('ignora espacios al inicio y al final de la consulta', () {
      expect(ids('  wifi  '), {'INC-102'});
    });

    test('sin texto devuelve todos los registros', () {
      expect(gestor.buscar('').length, 10);
      expect(gestor.buscar('   ').length, 10);
    });

    test('un texto sin coincidencias devuelve una lista vacía', () {
      expect(gestor.buscar('zzzz'), isEmpty);
    });
  });

  group('BUG-003: el tablero coincide con los datos', () {
    /// Totales que muestra el tablero, en el orden Pendientes / En proceso / Resueltas.
    List<int> tablero(GestorIncidencias g) => [
          g.contar('Pendiente'),
          g.contar('En proceso'),
          g.contar('Resuelta'),
        ];

    /// Totales calculados sobre la lista, sin pasar por contar().
    List<int> recuento(GestorIncidencias g) => [
          for (final e in ['Pendiente', 'En proceso', 'Resuelta'])
            g.incidencias.where((x) => x.estado == e).length,
        ];

    test('al arrancar muestra 5 / 2 / 3', () async {
      final g = await abrirApp();
      expect(tablero(g), [5, 2, 3]);
    });

    test('Pendiente a Resuelta, Pendientes baja y Resueltas sube', () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-101', 'Resuelta');
      expect(tablero(g), [4, 2, 4]);
      expect(tablero(g), recuento(g));
    });

    test('Resuelta a Pendiente, Pendientes sube y Resueltas baja', () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-104', 'Pendiente');
      expect(tablero(g), [6, 2, 2]);
      expect(tablero(g), recuento(g));
    });

    test('En proceso a Pendiente actualiza los tres contadores', () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-102', 'Pendiente');
      expect(tablero(g), [6, 1, 3]);
      expect(tablero(g), recuento(g));
    });

    test('los tres contadores siempre suman el total de registros', () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-101', 'Resuelta');
      await g.cambiarEstado('INC-103', 'En proceso');
      expect(tablero(g).reduce((a, b) => a + b), g.incidencias.length);
    });

    test('registrar una incidencia nueva suma un Pendiente', () async {
      final g = await abrirApp();
      await g.crear(
          'Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes');
      expect(tablero(g), [6, 2, 3]);
      expect(tablero(g), recuento(g));
    });

    test('tras reiniciar la app el tablero coincide con lo guardado', () async {
      final sesion1 = await abrirApp();
      await sesion1.cambiarEstado('INC-101', 'Resuelta');
      await sesion1.crear(
          'Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes');

      final sesion2 = await abrirApp();
      expect(tablero(sesion2), [5, 2, 4]);
      expect(tablero(sesion2), recuento(sesion2));
    });

    test('la búsqueda no cambia los totales del tablero', () async {
      final g = await abrirApp();
      final antes = tablero(g);
      expect(g.buscar('wifi').length, 1);
      expect(tablero(g), antes);
    });

    test('restablecer la demostración devuelve el tablero a 5 / 2 / 3',
        () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-101', 'Resuelta');
      await g.crear(
          'Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes');
      await g.reiniciarDemo();
      expect(tablero(g), [5, 2, 3]);
    });
  });

  group('FEAT-001: prioridad de las incidencias', () {
    Future<void> registrar(GestorIncidencias g, {String? prioridad}) {
      return prioridad == null
          ? g.crear('Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes')
          : g.crear('Título de prueba', 'Descripción', 'Cliente ficticio', 'Redes',
              prioridad: prioridad);
    }

    test('las incidencias de la semilla se abren con prioridad Media', () async {
      final g = await abrirApp();
      expect(g.incidencias.map((x) => x.prioridad).toSet(), {'Media'});
    });

    test('datos guardados antes de existir la prioridad se abren con Media',
        () async {
      final almacen = AlmacenLocal();
      await almacen.prefs.setString(
        almacen.clave,
        jsonEncode([
          {
            'id': 'INC-OLD',
            'titulo': 'Registro antiguo',
            'descripcion': 'Guardado sin prioridad',
            'cliente': 'Cliente ficticio',
            'categoria': 'Redes',
            'estado': 'En proceso',
            'fecha': '2026-09-01',
          }
        ]),
      );

      final g = await abrirApp();
      expect(g.incidencias.single.prioridad, 'Media');
      expect(g.incidencias.single.estado, 'En proceso');
    });

    test('una incidencia nueva sin prioridad indicada queda en Media', () async {
      final g = await abrirApp();
      await registrar(g);
      expect(g.incidencias.first.prioridad, 'Media');
    });

    test('una incidencia nueva con prioridad Alta la conserva tras reiniciar',
        () async {
      final sesion1 = await abrirApp();
      await registrar(sesion1, prioridad: 'Alta');
      final id = sesion1.incidencias.first.id;

      final sesion2 = await abrirApp();
      expect(sesion2.porId(id)!.prioridad, 'Alta');
    });

    test('registrar con una prioridad no aprobada se rechaza', () async {
      final g = await abrirApp();
      await expectLater(registrar(g, prioridad: 'Urgente'), throwsArgumentError);
      expect(g.incidencias.length, 10);
    });

    test('cambiar la prioridad se conserva tras reiniciar', () async {
      final sesion1 = await abrirApp();
      await sesion1.cambiarPrioridad('INC-101', 'Alta');
      expect(sesion1.porId('INC-101')!.prioridad, 'Alta');

      final sesion2 = await abrirApp();
      expect(sesion2.porId('INC-101')!.prioridad, 'Alta');
    });

    test('cambiar la prioridad de una incidencia no altera las demás',
        () async {
      final g = await abrirApp();
      await g.cambiarPrioridad('INC-101', 'Baja');

      final sesion2 = await abrirApp();
      for (final x in sesion2.incidencias) {
        expect(x.prioridad, x.id == 'INC-101' ? 'Baja' : 'Media',
            reason: 'prioridad de ${x.id}');
      }
    });

    test('cambiar a una prioridad no aprobada se rechaza y no modifica nada',
        () async {
      final g = await abrirApp();
      await expectLater(
          g.cambiarPrioridad('INC-101', 'Urgente'), throwsArgumentError);
      expect(g.porId('INC-101')!.prioridad, 'Media');

      final sesion2 = await abrirApp();
      expect(sesion2.porId('INC-101')!.prioridad, 'Media');
    });

    test('cambiar el estado no pierde la prioridad', () async {
      final sesion1 = await abrirApp();
      await sesion1.cambiarPrioridad('INC-101', 'Alta');
      await sesion1.cambiarEstado('INC-101', 'Resuelta');

      final sesion2 = await abrirApp();
      expect(sesion2.porId('INC-101')!.prioridad, 'Alta');
      expect(sesion2.porId('INC-101')!.estado, 'Resuelta');
    });

    test('cambiar la prioridad no altera el estado ni el tablero', () async {
      final g = await abrirApp();
      await g.cambiarPrioridad('INC-101', 'Alta');
      expect(g.porId('INC-101')!.estado, 'Pendiente');
      expect([g.contar('Pendiente'), g.contar('En proceso'), g.contar('Resuelta')],
          [5, 2, 3]);
    });
  });
}
