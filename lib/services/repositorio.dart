import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Fuente única de datos de la app.
///
/// Orden de carga (modo sin conexión incluido):
///   1. Firestore (si Firebase está configurado y hay internet)
///   2. Copia en caché del último Firestore leído (SharedPreferences)
///   3. JSON semilla empaquetado en assets/data/pijino.json
class Repositorio {
  Repositorio._();
  static final Repositorio instancia = Repositorio._();

  static const _cacheKey = 'cache_pijino_v1';
  static const colecciones = [
    'categorias',
    'contenidos',
    'eventos',
    'medios',
    'enlaces',
    'noticias',
    'contactos',
  ];

  bool firebaseActivo = false;
  DatosPijino? _datos;
  DatosPijino? get datos => _datos;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<DatosPijino> cargar({bool forzarRed = false}) async {
    if (_datos != null && !forzarRed) return _datos!;

    if (firebaseActivo) {
      try {
        final remoto = await _leerFirestore()
            .timeout(const Duration(seconds: 12));
        if (remoto.contenidos.isNotEmpty) {
          _datos = remoto;
          _guardarCache(remoto);
          return remoto;
        }
      } catch (_) {
        // Sin red o Firestore vacío: se sigue con caché / local.
      }
    }

    final cache = await _leerCache();
    if (cache != null) return _datos = cache;

    return _datos = await _leerLocal();
  }

  Future<DatosPijino> _leerFirestore() async {
    final mapa = <String, dynamic>{};
    final info = await _db.collection('municipio').doc('info').get();
    mapa['municipio'] = info.data() ?? <String, dynamic>{};
    for (final c in colecciones) {
      final snap = await _db.collection(c).get();
      mapa[c] = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    }
    return DatosPijino.fromJson(mapa, 'firestore');
  }

  Future<DatosPijino?> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final txt = prefs.getString(_cacheKey);
      if (txt == null) return null;
      return DatosPijino.fromJson(jsonDecode(txt), 'cache');
    } catch (_) {
      return null;
    }
  }

  Future<void> _guardarCache(DatosPijino d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(d.toJson()));
  }

  Future<DatosPijino> _leerLocal() async {
    final txt = await rootBundle.loadString('assets/data/pijino.json');
    return DatosPijino.fromJson(jsonDecode(txt), 'local');
  }

  // ---------------------------------------------------------------------
  // Escritura (panel administrativo y aportes de la comunidad)
  // ---------------------------------------------------------------------

  /// Aporte de un usuario (historia, foto, corrección). Queda pendiente de
  /// validación: no se publica hasta que un administrador lo apruebe.
  Future<void> enviarAporte({
    required String nombre,
    required String contacto,
    required String tipo,
    required String mensaje,
    String? enlace,
  }) async {
    if (!firebaseActivo) {
      throw StateError('Firebase no está configurado');
    }
    await _db.collection('aportes').add({
      'nombre': nombre,
      'contacto': contacto,
      'tipo': tipo,
      'mensaje': mensaje,
      'enlace': enlace,
      'estado': 'pendiente',
      'creado': FieldValue.serverTimestamp(),
    });
  }

  /// Sube una foto o video a Firebase Storage y lo registra en `medios`.
  Future<Medio> subirMedio({
    required File archivo,
    required TipoMedio tipo,
    required String titulo,
    required String credito,
    required String categoria,
  }) async {
    final ext = archivo.path.split('.').last.toLowerCase();
    final carpeta = tipo == TipoMedio.video ? 'videos' : 'fotos';
    final ref = FirebaseStorage.instance
        .ref('$carpeta/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(
      archivo,
      SettableMetadata(
          contentType: tipo == TipoMedio.video ? 'video/$ext' : 'image/$ext'),
    );
    final url = await ref.getDownloadURL();
    final doc = _db.collection('medios').doc();
    final medio = Medio(
      id: doc.id,
      tipo: tipo,
      titulo: titulo,
      url: url,
      credito: credito,
      categoria: categoria,
    );
    await doc.set(medio.toMap());
    _datos = null; // forzar recarga
    return medio;
  }

  /// Registra un video de YouTube (solo el id) en `medios`.
  Future<Medio> agregarYoutube({
    required String urlOId,
    required String titulo,
    required String credito,
    required String categoria,
  }) async {
    final id = extraerIdYoutube(urlOId);
    if (id == null) throw FormatException('Enlace de YouTube no válido');
    final doc = _db.collection('medios').doc('yt-$id');
    final medio = Medio(
      id: doc.id,
      tipo: TipoMedio.video,
      titulo: titulo,
      youtube: id,
      credito: credito,
      categoria: categoria,
    );
    await doc.set(medio.toMap());
    _datos = null;
    return medio;
  }

  Future<void> guardarContenido(Contenido c) async {
    await _db.collection('contenidos').doc(c.id).set(c.toMap());
    _datos = null;
  }

  Future<void> guardarEvento(Evento e) async {
    await _db.collection('eventos').doc(e.id).set(e.toMap());
    _datos = null;
  }

  Future<void> guardarEnlace(Enlace e) async {
    await _db.collection('enlaces').doc(e.id).set(e.toMap());
    _datos = null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> aportesPendientes() => _db
      .collection('aportes')
      .where('estado', isEqualTo: 'pendiente')
      .snapshots();

  Future<void> marcarAporte(String id, String estado) =>
      _db.collection('aportes').doc(id).update({'estado': estado});

  /// Carga inicial: copia el JSON semilla a Firestore (solo administradores).
  Future<int> sembrarDesdeJsonLocal() async {
    final local = await _leerLocal();
    final json = local.toJson();
    var escritos = 0;
    var lote = _db.batch();
    var enLote = 0;

    Future<void> commitSiLleno() async {
      if (enLote >= 400) {
        await lote.commit();
        lote = _db.batch();
        enLote = 0;
      }
    }

    lote.set(_db.collection('municipio').doc('info'),
        Map<String, dynamic>.from(json['municipio']));
    enLote++;
    for (final c in colecciones) {
      for (final item in (json[c] as List)) {
        final m = Map<String, dynamic>.from(item);
        lote.set(_db.collection(c).doc(m['id']), m);
        enLote++;
        escritos++;
        await commitSiLleno();
      }
    }
    await lote.commit();
    _datos = null;
    return escritos;
  }
}

/// Acepta: id directo, youtu.be/ID, youtube.com/watch?v=ID, /shorts/ID.
String? extraerIdYoutube(String entrada) {
  final t = entrada.trim();
  final directo = RegExp(r'^[A-Za-z0-9_-]{11}$');
  if (directo.hasMatch(t)) return t;
  final patrones = [
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
    RegExp(r'[?&]v=([A-Za-z0-9_-]{11})'),
    RegExp(r'/shorts/([A-Za-z0-9_-]{11})'),
    RegExp(r'/embed/([A-Za-z0-9_-]{11})'),
  ];
  for (final p in patrones) {
    final m = p.firstMatch(t);
    if (m != null) return m.group(1);
  }
  return null;
}
