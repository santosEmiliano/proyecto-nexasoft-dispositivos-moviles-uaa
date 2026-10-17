class Incidencia {
  static const prioridades = ['Baja', 'Media', 'Alta'];
  static const prioridadPorDefecto = 'Media';

  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  String prioridad;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    this.prioridad = prioridadPorDefecto,
  });

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    final prioridad = m['prioridad'];
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      // Los registros anteriores a la prioridad no traen el campo, así que aquí se asigna la prioridad por defecto.
      prioridad:
          prioridades.contains(prioridad) ? prioridad : prioridadPorDefecto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      'prioridad': prioridad,
    };
  }
}
