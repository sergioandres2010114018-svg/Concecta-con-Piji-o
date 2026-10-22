import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/apis.dart';
import '../services/auth.dart';
import '../services/repositorio.dart';
import '../theme.dart';

/// Panel administrativo: actualizar contenidos sin publicar otra versión de
/// la app (mejora propuesta en el formato del proyecto).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Repositorio.instancia.firebaseActivo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel administrativo')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'El panel necesita Firebase.\n\n'
            '1. Crea un proyecto en console.firebase.google.com\n'
            '2. Activa Firestore, Storage y Authentication (correo/contraseña)\n'
            '3. Ejecuta "flutterfire configure" en el proyecto\n'
            '4. Cambia firebaseConfigurado = true en lib/config.dart\n\n'
            'Mientras tanto la app funciona con los datos incluidos.',
            style: TextStyle(height: 1.5),
          ),
        ),
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, s) =>
          s.data == null ? const _Login() : const _Panel(),
    );
  }
}

class _Login extends StatefulWidget {
  const _Login();
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  String? _error;
  bool _cargando = false;

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _correo.text.trim(), password: _clave.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'No se pudo ingresar (${e.code}).');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso de administradores')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo')),
        TextField(
            controller: _clave,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña')),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: _cargando ? null : _entrar,
            child: const Text('Ingresar')),
      ]),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel administrativo'),
          actions: [
            IconButton(
                tooltip: 'Salir',
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut()),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Subir foto/video'),
            Tab(text: 'Video YouTube'),
            Tab(text: 'Nuevo contenido'),
            Tab(text: 'Aportes'),
            Tab(text: 'Usuarios'),
          ]),
        ),
        body: const TabBarView(children: [
          _SubirMedio(),
          _AgregarYoutube(),
          _NuevoContenido(),
          _Aportes(),
          _Usuarios(),
        ]),
      ),
    );
  }
}

List<DropdownMenuItem<String>> _itemsCategorias() => (Repositorio
            .instancia.datos?.categorias ??
        const <Categoria>[])
    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
    .toList();

void _aviso(BuildContext c, String t) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

class _SubirMedio extends StatefulWidget {
  const _SubirMedio();
  @override
  State<_SubirMedio> createState() => _SubirMedioState();
}

class _SubirMedioState extends State<_SubirMedio> {
  final _titulo = TextEditingController();
  final _credito = TextEditingController();
  String _categoria = 'turismo';
  XFile? _archivo;
  TipoMedio _tipo = TipoMedio.foto;
  bool _subiendo = false;

  Future<void> _elegir(TipoMedio t, ImageSource src) async {
    final p = ImagePicker();
    final f = t == TipoMedio.foto
        ? await p.pickImage(source: src, maxWidth: 1920, imageQuality: 82)
        : await p.pickVideo(source: src, maxDuration: const Duration(minutes: 5));
    if (f != null) setState(() {
      _archivo = f;
      _tipo = t;
    });
  }

  Future<void> _subir() async {
    if (_archivo == null || _titulo.text.trim().isEmpty) {
      _aviso(context, 'Elige un archivo y escribe un título');
      return;
    }
    setState(() => _subiendo = true);
    try {
      await Repositorio.instancia.subirMedio(
        archivo: File(_archivo!.path),
        tipo: _tipo,
        titulo: _titulo.text.trim(),
        credito: _credito.text.trim(),
        categoria: _categoria,
      );
      if (!mounted) return;
      _aviso(context, 'Archivo publicado en la galería');
      setState(() {
        _archivo = null;
        _titulo.clear();
      });
    } catch (e) {
      if (mounted) _aviso(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            icon: const Icon(Icons.photo),
            label: const Text('Foto de galería'),
            onPressed: () => _elegir(TipoMedio.foto, ImageSource.gallery)),
        OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar foto'),
            onPressed: () => _elegir(TipoMedio.foto, ImageSource.camera)),
        OutlinedButton.icon(
            icon: const Icon(Icons.videocam),
            label: const Text('Video'),
            onPressed: () => _elegir(TipoMedio.video, ImageSource.gallery)),
      ]),
      if (_archivo != null) ...[
        const SizedBox(height: 12),
        _tipo == TipoMedio.foto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_archivo!.path),
                    height: 200, fit: BoxFit.cover))
            : ListTile(
                leading: const Icon(Icons.movie, color: Paleta.atardecer),
                title: Text(_archivo!.name)),
      ],
      TextField(
          controller: _titulo,
          decoration: const InputDecoration(labelText: 'Título')),
      TextField(
          controller: _credito,
          decoration: const InputDecoration(
              labelText: 'Autor / crédito (con autorización de uso)')),
      DropdownButtonFormField<String>(
        value: _categoria,
        items: _itemsCategorias(),
        decoration: const InputDecoration(labelText: 'Categoría'),
        onChanged: (v) => setState(() => _categoria = v!),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _subiendo ? null : _subir,
        icon: const Icon(Icons.cloud_upload),
        label: Text(_subiendo ? 'Subiendo…' : 'Publicar'),
      ),
    ]);
  }
}

class _AgregarYoutube extends StatefulWidget {
  const _AgregarYoutube();
  @override
  State<_AgregarYoutube> createState() => _AgregarYoutubeState();
}

class _AgregarYoutubeState extends State<_AgregarYoutube> {
  final _url = TextEditingController();
  final _titulo = TextEditingController();
  final _credito = TextEditingController();
  String _categoria = 'cultura';

  Future<void> _autocompletar() async {
    final id = extraerIdYoutube(_url.text);
    if (id == null) {
      _aviso(context, 'Enlace de YouTube no válido');
      return;
    }
    final info = await ApiYoutube.info(id);
    if (info == null) {
      if (mounted) _aviso(context, 'No se encontró el video');
      return;
    }
    setState(() {
      _titulo.text = info.titulo;
      _credito.text = info.autor;
    });
  }

  Future<void> _guardar() async {
    try {
      await Repositorio.instancia.agregarYoutube(
        urlOId: _url.text,
        titulo: _titulo.text.trim(),
        credito: _credito.text.trim(),
        categoria: _categoria,
      );
      if (!mounted) return;
      _aviso(context, 'Video agregado');
      _url.clear();
      _titulo.clear();
      _credito.clear();
    } catch (e) {
      if (mounted) _aviso(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        controller: _url,
        decoration: InputDecoration(
          labelText: 'Enlace de YouTube',
          suffixIcon: IconButton(
              tooltip: 'Traer título y autor',
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _autocompletar),
        ),
      ),
      TextField(
          controller: _titulo,
          decoration: const InputDecoration(labelText: 'Título')),
      TextField(
          controller: _credito,
          decoration: const InputDecoration(labelText: 'Canal / autor')),
      DropdownButtonFormField<String>(
        value: _categoria,
        items: _itemsCategorias(),
        decoration: const InputDecoration(labelText: 'Categoría'),
        onChanged: (v) => setState(() => _categoria = v!),
      ),
      const SizedBox(height: 20),
      FilledButton(onPressed: _guardar, child: const Text('Agregar video')),
    ]);
  }
}

class _NuevoContenido extends StatefulWidget {
  const _NuevoContenido();
  @override
  State<_NuevoContenido> createState() => _NuevoContenidoState();
}

class _NuevoContenidoState extends State<_NuevoContenido> {
  final _titulo = TextEditingController();
  final _resumen = TextEditingController();
  final _cuerpo = TextEditingController();
  final _fuente = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  String _categoria = 'historia';

  String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úù]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _guardar() async {
    if (_titulo.text.trim().isEmpty || _cuerpo.text.trim().isEmpty) {
      _aviso(context, 'Título y texto son obligatorios');
      return;
    }
    final lat = double.tryParse(_lat.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.replaceAll(',', '.'));
    final c = Contenido(
      id: _slug(_titulo.text),
      categoria: _categoria,
      titulo: _titulo.text.trim(),
      resumen: _resumen.text.trim(),
      cuerpo: _cuerpo.text.trim(),
      ubicacion: lat != null && lng != null ? Ubicacion(lat, lng) : null,
      fuentes: _fuente.text.trim().isEmpty
          ? const []
          : [Fuente(titulo: 'Fuente', url: _fuente.text.trim())],
    );
    try {
      await Repositorio.instancia.guardarContenido(c);
      if (!mounted) return;
      _aviso(context, 'Contenido publicado');
      for (final t in [_titulo, _resumen, _cuerpo, _fuente, _lat, _lng]) {
        t.clear();
      }
    } catch (e) {
      if (mounted) _aviso(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(
        value: _categoria,
        items: _itemsCategorias(),
        decoration: const InputDecoration(labelText: 'Categoría'),
        onChanged: (v) => setState(() => _categoria = v!),
      ),
      TextField(
          controller: _titulo,
          decoration: const InputDecoration(labelText: 'Título')),
      TextField(
          controller: _resumen,
          decoration: const InputDecoration(labelText: 'Resumen (1 línea)')),
      TextField(
          controller: _cuerpo,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Texto completo')),
      TextField(
          controller: _fuente,
          decoration: const InputDecoration(labelText: 'Enlace de la fuente')),
      Row(children: [
        Expanded(
            child: TextField(
                controller: _lat,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitud'))),
        const SizedBox(width: 12),
        Expanded(
            child: TextField(
                controller: _lng,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitud'))),
      ]),
      const SizedBox(height: 20),
      FilledButton(onPressed: _guardar, child: const Text('Publicar')),
      const SizedBox(height: 32),
      const Divider(),
      const Text('Carga inicial',
          style: TextStyle(fontWeight: FontWeight.w800)),
      const Text(
          'Copia todos los contenidos, eventos, fotos, videos y enlaces incluidos en la app a Firestore. Hazlo una sola vez al configurar el proyecto.'),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.upload),
        label: const Text('Sembrar base de datos'),
        onPressed: () async {
          final n = await Repositorio.instancia.sembrarDesdeJsonLocal();
          if (context.mounted) _aviso(context, '$n registros cargados');
        },
      ),
    ]);
  }
}

class _Aportes extends StatelessWidget {
  const _Aportes();

  @override
  Widget build(BuildContext context) {
    final repo = Repositorio.instancia;
    return StreamBuilder(
      stream: repo.aportesPendientes(),
      builder: (_, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay aportes pendientes.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final a = docs[i].data();
            return Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a['tipo']} · ${a['nombre']}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${a['contacto']}',
                        style: const TextStyle(color: Paleta.tierra)),
                    const SizedBox(height: 6),
                    Text('${a['mensaje']}'),
                    if (a['enlace'] != null) Text('${a['enlace']}'),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () =>
                              repo.marcarAporte(docs[i].id, 'descartado'),
                          child: const Text('Descartar')),
                      FilledButton(
                          onPressed: () =>
                              repo.marcarAporte(docs[i].id, 'validado'),
                          child: const Text('Marcar validado')),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Usuarios extends StatelessWidget {
  const _Usuarios();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: Auth.instancia.listarUsuarios(),
      builder: (_, s) {
        if (s.hasError) return Center(child: Text('Error: ${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final us = s.data!;
        if (us.isEmpty) return const Center(child: Text('Aún no hay usuarios registrados.'));
        return ListView.separated(
          itemCount: us.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${us.length} usuarios registrados',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              );
            }
            final u = us[i - 1];
            return ListTile(
              leading: const Icon(Icons.person, color: Paleta.cienaga),
              title: Text(u.nombre),
              subtitle: Text('${u.perfil}\n${u.correo} · ${u.telefono}'),
              isThreeLine: true,
              trailing: Text(
                  '${u.creado.day}/${u.creado.month}/${u.creado.year}',
                  style: const TextStyle(fontSize: 12)),
            );
          },
        );
      },
    );
  }
}
