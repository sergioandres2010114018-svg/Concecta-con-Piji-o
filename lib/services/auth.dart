import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositorio.dart';

/// Perfil de un usuario registrado en la app.
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String perfil; // Habitante, Visitante, Estudiante, Comerciante…
  final String rol; // usuario | admin
  final DateTime creado;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.perfil,
    this.rol = 'usuario',
    required this.creado,
  });

  bool get esAdmin => rol == 'admin';

  factory Usuario.fromMap(String id, Map<String, dynamic> m) => Usuario(
        id: id,
        nombre: m['nombre'] ?? '',
        correo: m['correo'] ?? '',
        telefono: m['telefono'] ?? '',
        perfil: m['perfil'] ?? 'Visitante',
        rol: m['rol'] ?? 'usuario',
        creado: m['creado'] is Timestamp
            ? (m['creado'] as Timestamp).toDate()
            : DateTime.tryParse('${m['creado']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'correo': correo,
        'telefono': telefono,
        'perfil': perfil,
        'rol': rol,
        'creado': creado.toIso8601String(),
      };
}

class ErrorAuth implements Exception {
  final String mensaje;
  ErrorAuth(this.mensaje);
  @override
  String toString() => mensaje;
}

/// Registro e inicio de sesión.
///
/// - Con Firebase: Firebase Authentication (correo/contraseña) y el perfil
///   en la colección Firestore `usuarios/{uid}`.
/// - Sin Firebase (modo local): los usuarios se guardan en el teléfono con
///   la contraseña cifrada (SHA-256 con sal), útil para pruebas y la
///   sustentación sin internet.
class Auth extends ChangeNotifier {
  Auth._();
  static final Auth instancia = Auth._();

  static const _kUsuarios = 'usuarios_locales_v1';
  static const _kSesion = 'sesion_local_v1';

  Usuario? _actual;
  bool _invitado = false;
  Usuario? get actual => _actual;
  bool get invitado => _invitado;
  bool get conSesion => _actual != null || _invitado;

  bool get _firebase => Repositorio.instancia.firebaseActivo;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Restaura la sesión guardada al abrir la app.
  Future<void> restaurar() async {
    if (_firebase) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) _actual = await _perfilFirebase(u);
    } else {
      final p = await SharedPreferences.getInstance();
      final correo = p.getString(_kSesion);
      if (correo != null) {
        final datos = (await _locales())[correo];
        if (datos != null) _actual = Usuario.fromMap(correo, datos);
      }
    }
    notifyListeners();
  }

  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String telefono,
    required String perfil,
    required String clave,
  }) async {
    correo = correo.trim().toLowerCase();
    final u = Usuario(
      id: correo,
      nombre: nombre.trim(),
      correo: correo,
      telefono: telefono.trim(),
      perfil: perfil,
      creado: DateTime.now(),
    );
    if (_firebase) {
      try {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: correo, password: clave);
        await cred.user!.updateDisplayName(u.nombre);
        final conId = Usuario(
            id: cred.user!.uid,
            nombre: u.nombre,
            correo: u.correo,
            telefono: u.telefono,
            perfil: u.perfil,
            creado: u.creado);
        await _db.collection('usuarios').doc(cred.user!.uid).set({
          ...conId.toMap(),
          'creado': FieldValue.serverTimestamp(),
        });
        _actual = conId;
      } on FirebaseAuthException catch (e) {
        throw ErrorAuth(_mensajeFirebase(e.code));
      }
    } else {
      final usuarios = await _locales();
      if (usuarios.containsKey(correo)) {
        throw ErrorAuth('Ya existe una cuenta con ese correo. Inicia sesión.');
      }
      final sal = _sal();
      usuarios[correo] = {
        ...u.toMap(),
        'sal': sal,
        'hash': _hash(clave, sal),
      };
      await _guardarLocales(usuarios);
      await _guardarSesion(correo);
      _actual = u;
    }
    _invitado = false;
    notifyListeners();
    return _actual!;
  }

  Future<Usuario> ingresar(String correo, String clave) async {
    correo = correo.trim().toLowerCase();
    if (_firebase) {
      try {
        final cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: correo, password: clave);
        _actual = await _perfilFirebase(cred.user!);
      } on FirebaseAuthException catch (e) {
        throw ErrorAuth(_mensajeFirebase(e.code));
      }
    } else {
      final datos = (await _locales())[correo];
      if (datos == null || _hash(clave, datos['sal']) != datos['hash']) {
        throw ErrorAuth('Correo o contraseña incorrectos.');
      }
      await _guardarSesion(correo);
      _actual = Usuario.fromMap(correo, datos);
    }
    _invitado = false;
    notifyListeners();
    return _actual!;
  }

  Future<void> recuperarClave(String correo) async {
    if (!_firebase) {
      throw ErrorAuth(
          'En modo local la contraseña no se puede recuperar. Crea una cuenta nueva.');
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: correo.trim());
  }

  void entrarComoInvitado() {
    _invitado = true;
    notifyListeners();
  }

  Future<void> salir() async {
    if (_firebase) await FirebaseAuth.instance.signOut();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSesion);
    _actual = null;
    _invitado = false;
    notifyListeners();
  }

  /// Lista de usuarios registrados (para el panel administrativo).
  Future<List<Usuario>> listarUsuarios() async {
    if (_firebase) {
      final s = await _db
          .collection('usuarios')
          .orderBy('creado', descending: true)
          .get();
      return s.docs.map((d) => Usuario.fromMap(d.id, d.data())).toList();
    }
    final l = (await _locales())
        .entries
        .map((e) => Usuario.fromMap(e.key, e.value))
        .toList()
      ..sort((a, b) => b.creado.compareTo(a.creado));
    return l;
  }

  // ---------------------------------------------------------------------

  Future<Usuario> _perfilFirebase(User u) async {
    final doc = await _db.collection('usuarios').doc(u.uid).get();
    if (doc.exists) return Usuario.fromMap(u.uid, doc.data()!);
    // Usuario creado en la consola sin perfil: se crea uno básico.
    final nuevo = Usuario(
      id: u.uid,
      nombre: u.displayName ?? u.email?.split('@').first ?? 'Usuario',
      correo: u.email ?? '',
      telefono: '',
      perfil: 'Visitante',
      creado: DateTime.now(),
    );
    await _db.collection('usuarios').doc(u.uid).set(nuevo.toMap());
    return nuevo;
  }

  Future<Map<String, Map<String, dynamic>>> _locales() async {
    final p = await SharedPreferences.getInstance();
    final txt = p.getString(_kUsuarios);
    if (txt == null) return {};
    final m = jsonDecode(txt) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
  }

  Future<void> _guardarLocales(Map<String, Map<String, dynamic>> u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUsuarios, jsonEncode(u));
  }

  Future<void> _guardarSesion(String correo) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSesion, correo);
  }

  String _sal() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String clave, String sal) =>
      sha256.convert(utf8.encode('$sal:$clave')).toString();

  String _mensajeFirebase(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo. Inicia sesión.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Inténtalo de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      default:
        return 'No se pudo completar ($code).';
    }
  }
}
