import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';

Map<String, dynamic> registro({Object? prioridad, bool incluirPrioridad = true}) {
  return {
    'id': 'INC-T1',
    'titulo': 'Prueba',
    'descripcion': 'Caso de ejemplo',
    'cliente': 'Cliente ficticio',
    'categoria': 'Redes',
    'estado': 'Pendiente',
    'fecha': '2026-10-16',
    if (incluirPrioridad) 'prioridad': prioridad,
  };
}

void main() {
  group('FEAT-001: prioridad en el modelo', () {
    test('un registro antiguo sin prioridad se abre como Media', () {
      final x = Incidencia.desdeJson(registro(incluirPrioridad: false));
      expect(x.prioridad, 'Media');
    });

    test('las tres prioridades aprobadas se conservan', () {
      for (final p in ['Baja', 'Media', 'Alta']) {
        expect(Incidencia.desdeJson(registro(prioridad: p)).prioridad, p);
      }
    });

    test('un valor no aprobado se reemplaza por Media', () {
      for (final p in [null, '', 'Urgente', 'alta', 3]) {
        expect(Incidencia.desdeJson(registro(prioridad: p)).prioridad, 'Media',
            reason: 'valor: $p');
      }
    });

    test('al crear sin indicar prioridad queda en Media', () {
      final x = Incidencia(
        id: 'INC-T2',
        titulo: 'Prueba',
        descripcion: 'Caso de ejemplo',
        cliente: 'Cliente ficticio',
        categoria: 'Redes',
        estado: 'Pendiente',
        fecha: '2026-10-16',
      );
      expect(x.prioridad, 'Media');
    });

    test('toJson incluye la prioridad y se puede volver a leer', () {
      final x = Incidencia.desdeJson(registro(prioridad: 'Alta'));
      expect(x.toJson()['prioridad'], 'Alta');
      expect(Incidencia.desdeJson(x.toJson()).prioridad, 'Alta');
    });
  });
}
