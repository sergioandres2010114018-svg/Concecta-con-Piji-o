// Modelos de datos de APP-Conecta con Pijiño.
// Cada modelo se construye desde un Map (Firestore o JSON local) y se
// serializa de vuelta con toMap() para guardarlo en Firestore.

class Fuente {
  final String titulo;
  final String url;
  const Fuente({required this.titulo, required this.url});

  factory Fuente.fromMap(Map<String, dynamic> m) =>
      Fuente(titulo: m['titulo'] ?? '', url: m['url'] ?? '');

  Map<String, dynamic> toMap() => {'titulo': titulo, 'url': url};
}

class Ubicacion {
  final double lat;
  final double lng;
  final bool aprox;
  const Ubicacion(this.lat, this.lng, {this.aprox = false});

  factory Ubicacion.fromMap(Map<String, dynamic> m) => Ubicacion(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
        aprox: m['aprox'] ?? false,
      );

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'aprox': aprox};
}

class Categoria {
  final String id;
  final String nombre;
  final String icono;
  final String color;
  const Categoria(
      {required this.id,
      required this.nombre,
      required this.icono,
      required this.color});

  factory Categoria.fromMap(Map<String, dynamic> m) => Categoria(
        id: m['id'],
        nombre: m['nombre'],
        icono: m['icono'] ?? 'info',
        color: m['color'] ?? '#BD6B2F',
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'nombre': nombre, 'icono': icono, 'color': color};
}

class Contenido {
  final String id;
  final String categoria;
  final String titulo;
  final String resumen;
  final String cuerpo;
  final List<String> imagenes; // ids de Medio
  final List<String> videos; // ids de Medio
  final Ubicacion? ubicacion;
  final List<Fuente> fuentes;

  const Contenido({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.resumen,
    required this.cuerpo,
    this.imagenes = const [],
    this.videos = const [],
    this.ubicacion,
    this.fuentes = const [],
  });

  factory Contenido.fromMap(Map<String, dynamic> m) => Contenido(
        id: m['id'],
        categoria: m['categoria'],
        titulo: m['titulo'],
        resumen: m['resumen'] ?? '',
        cuerpo: m['cuerpo'] ?? '',
        imagenes: List<String>.from(m['imagenes'] ?? const []),
        videos: List<String>.from(m['videos'] ?? const []),
        ubicacion: m['ubicacion'] == null
            ? null
            : Ubicacion.fromMap(Map<String, dynamic>.from(m['ubicacion'])),
        fuentes: (m['fuentes'] as List? ?? const [])
            .map((f) => Fuente.fromMap(Map<String, dynamic>.from(f)))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoria': categoria,
        'titulo': titulo,
        'resumen': resumen,
        'cuerpo': cuerpo,
        'imagenes': imagenes,
        'videos': videos,
        'ubicacion': ubicacion?.toMap(),
        'fuentes': fuentes.map((f) => f.toMap()).toList(),
      };
}

enum TipoMedio { foto, video }

class Medio {
  final String id;
  final TipoMedio tipo;
  final String titulo;
  final String? url; // fotos o videos subidos a Firebase Storage
  final String? youtube; // id de YouTube
  final String credito;
  final String? fuente;
  final String categoria;

  const Medio({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.url,
    this.youtube,
    this.credito = '',
    this.fuente,
    this.categoria = 'general',
  });

  bool get esYoutube => youtube != null && youtube!.isNotEmpty;

  /// Miniatura: para YouTube usa la imagen pública del video.
  String get miniatura => esYoutube
      ? 'https://i.ytimg.com/vi/$youtube/hqdefault.jpg'
      : (url ?? '');

  factory Medio.fromMap(Map<String, dynamic> m) => Medio(
        id: m['id'],
        tipo: m['tipo'] == 'video' ? TipoMedio.video : TipoMedio.foto,
        titulo: m['titulo'] ?? '',
        url: m['url'],
        youtube: m['youtube'],
        credito: m['credito'] ?? '',
        fuente: m['fuente'],
        categoria: m['categoria'] ?? 'general',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tipo': tipo == TipoMedio.video ? 'video' : 'foto',
        'titulo': titulo,
        'url': url,
        'youtube': youtube,
        'credito': credito,
        'fuente': fuente,
        'categoria': categoria,
      };
}

class Evento {
  final String id;
  final String titulo;
  final int? mes;
  final int? dia;
  final String lugar;
  final String descripcion;
  final String? imagen;
  final String? video;

  const Evento({
    required this.id,
    required this.titulo,
    this.mes,
    this.dia,
    required this.lugar,
    required this.descripcion,
    this.imagen,
    this.video,
  });

  /// Próxima ocurrencia del evento (anual). Null si la fecha no está definida.
  DateTime? proximaFecha([DateTime? hoy]) {
    if (mes == null) return null;
    final ahora = hoy ?? DateTime.now();
    final d = dia ?? 1;
    var f = DateTime(ahora.year, mes!, d);
    final hoySinHora = DateTime(ahora.year, ahora.month, ahora.day);
    if (f.isBefore(hoySinHora)) f = DateTime(ahora.year + 1, mes!, d);
    return f;
  }

  bool get fechaExacta => mes != null && dia != null;

  factory Evento.fromMap(Map<String, dynamic> m) => Evento(
        id: m['id'],
        titulo: m['titulo'],
        mes: m['mes'],
        dia: m['dia'],
        lugar: m['lugar'] ?? '',
        descripcion: m['descripcion'] ?? '',
        imagen: m['imagen'],
        video: m['video'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'mes': mes,
        'dia': dia,
        'lugar': lugar,
        'descripcion': descripcion,
        'imagen': imagen,
        'video': video,
      };
}

class Enlace {
  final String id;
  final String tipo; // red_social | institucional | prensa | turismo
  final String? red; // facebook | youtube | instagram | tiktok
  final String titulo;
  final String url;
  const Enlace(
      {required this.id,
      required this.tipo,
      this.red,
      required this.titulo,
      required this.url});

  factory Enlace.fromMap(Map<String, dynamic> m) => Enlace(
        id: m['id'],
        tipo: m['tipo'] ?? 'institucional',
        red: m['red'],
        titulo: m['titulo'],
        url: m['url'],
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'tipo': tipo, 'red': red, 'titulo': titulo, 'url': url};
}

class Noticia {
  final String id;
  final DateTime fecha;
  final String titulo;
  final String resumen;
  final String url;
  const Noticia(
      {required this.id,
      required this.fecha,
      required this.titulo,
      required this.resumen,
      required this.url});

  factory Noticia.fromMap(Map<String, dynamic> m) => Noticia(
        id: m['id'],
        fecha: DateTime.parse(m['fecha']),
        titulo: m['titulo'],
        resumen: m['resumen'] ?? '',
        url: m['url'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String().substring(0, 10),
        'titulo': titulo,
        'resumen': resumen,
        'url': url,
      };
}

class Contacto {
  final String id;
  final String titulo;
  final String? telefono;
  final String? correo;
  final String descripcion;
  const Contacto(
      {required this.id,
      required this.titulo,
      this.telefono,
      this.correo,
      this.descripcion = ''});

  factory Contacto.fromMap(Map<String, dynamic> m) => Contacto(
        id: m['id'],
        titulo: m['titulo'],
        telefono: m['telefono'],
        correo: m['correo'],
        descripcion: m['descripcion'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'telefono': telefono,
        'correo': correo,
        'descripcion': descripcion,
      };
}

/// Toda la información del municipio en memoria.
class DatosPijino {
  final Map<String, dynamic> municipio;
  final List<Categoria> categorias;
  final List<Contenido> contenidos;
  final List<Evento> eventos;
  final Map<String, Medio> medios;
  final List<Enlace> enlaces;
  final List<Noticia> noticias;
  final List<Contacto> contactos;
  final String origen; // 'firestore' | 'cache' | 'local'

  const DatosPijino({
    required this.municipio,
    required this.categorias,
    required this.contenidos,
    required this.eventos,
    required this.medios,
    required this.enlaces,
    required this.noticias,
    required this.contactos,
    required this.origen,
  });

  List<Contenido> porCategoria(String cat) =>
      contenidos.where((c) => c.categoria == cat).toList();

  Categoria? categoria(String id) {
    for (final c in categorias) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Evento> get eventosOrdenados {
    final conFecha = eventos.where((e) => e.mes != null).toList()
      ..sort((a, b) => a.proximaFecha()!.compareTo(b.proximaFecha()!));
    final sinFecha = eventos.where((e) => e.mes == null);
    return [...conFecha, ...sinFecha];
  }

  List<Medio> get fotos =>
      medios.values.where((m) => m.tipo == TipoMedio.foto).toList();
  List<Medio> get videos =>
      medios.values.where((m) => m.tipo == TipoMedio.video).toList();

  factory DatosPijino.fromJson(Map<String, dynamic> j, String origen) {
    List<Map<String, dynamic>> lista(String k) => (j[k] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return DatosPijino(
      municipio: Map<String, dynamic>.from(j['municipio'] ?? const {}),
      categorias: lista('categorias').map(Categoria.fromMap).toList(),
      contenidos: lista('contenidos').map(Contenido.fromMap).toList(),
      eventos: lista('eventos').map(Evento.fromMap).toList(),
      medios: {
        for (final m in lista('medios').map(Medio.fromMap)) m.id: m,
      },
      enlaces: lista('enlaces').map(Enlace.fromMap).toList(),
      noticias: lista('noticias').map(Noticia.fromMap).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha)),
      contactos: lista('contactos').map(Contacto.fromMap).toList(),
      origen: origen,
    );
  }

  Map<String, dynamic> toJson() => {
        'municipio': municipio,
        'categorias': categorias.map((e) => e.toMap()).toList(),
        'contenidos': contenidos.map((e) => e.toMap()).toList(),
        'eventos': eventos.map((e) => e.toMap()).toList(),
        'medios': medios.values.map((e) => e.toMap()).toList(),
        'enlaces': enlaces.map((e) => e.toMap()).toList(),
        'noticias': noticias.map((e) => e.toMap()).toList(),
        'contactos': contactos.map((e) => e.toMap()).toList(),
      };
}
