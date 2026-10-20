import 'package:diacritic/diacritic.dart';

import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  /// Quita acentos y pasa a minúsculas, para comparar sin distinguirlos.
  String _normalizar(String texto) => removeDiacritics(texto).toLowerCase();

  /// Valores del filtro que serían lo mismo que no filtrar.
  static const todosLosEstados = 'Todos';
  static const todasLasPrioridades = 'Todas';

  /// Aplica al mismo tiempo el filtro de texto, estado y prioridad.
  /// Un filtro nulo o con valor de "Todos" o "Todas" no filtra nada.
  List<Incidencia> buscar(String texto, {String? estado, String? prioridad}) {
    final consulta = _normalizar(texto.trim());
    final porEstado = estado != null && estado != todosLosEstados;
    final porPrioridad = prioridad != null && prioridad != todasLasPrioridades;

    return incidencias.where((x) {
      if (porEstado && x.estado != estado) return false;
      if (porPrioridad && x.prioridad != prioridad) return false;
      return consulta.isEmpty ||
          _normalizar(x.titulo).contains(consulta) ||
          _normalizar(x.descripcion).contains(consulta);
    }).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  /// Cuenta siempre sobre la lista completa, así el tablero no depende de la búsqueda
  /// ni de ningún contador guardado aparte.
  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    final incidencia = porId(id);
    if (incidencia == null) return;

    final anterior = incidencia.estado;
    incidencia.estado = estado;
    try {
      await datos.guardar(incidencias);
    } catch (_) {
      // Si no se pudo guardar, la lista no debe mostrar un estado que no está en el almacenamiento local
      incidencia.estado = anterior;
      rethrow;
    }
  }

  Future<void> cambiarPrioridad(String id, String prioridad) async {
    _validarPrioridad(prioridad);
    final incidencia = porId(id);
    if (incidencia == null) return;

    final anterior = incidencia.prioridad;
    incidencia.prioridad = prioridad;
    try {
      await datos.guardar(incidencias);
    } catch (_) {
      incidencia.prioridad = anterior;
      rethrow;
    }
  }

  void _validarPrioridad(String prioridad) {
    if (!Incidencia.prioridades.contains(prioridad)) {
      throw ArgumentError.value(
          prioridad, 'prioridad', 'Debe ser Baja, Media o Alta');
    }
  }

  Future<void> crear(
      String titulo, String descripcion, String cliente, String categoria,
      {String prioridad = Incidencia.prioridadPorDefecto}) async {
    _validarPrioridad(prioridad);
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
      prioridad: prioridad,
    );
    incidencias.insert(0, nuevo);
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
