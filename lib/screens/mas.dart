import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/apis.dart';
import '../services/auth.dart';
import '../services/favoritos.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'admin.dart';
import 'detalle.dart';
import 'eventos.dart';

/// Sección "Más": información general, redes y enlaces, contacto, aportes,
/// favoritos y acceso al panel administrativo.
class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void ir(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Image.asset('assets/img/logo_crop.jpg', width: 64),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'APP-Conecta con Pijiño\nProyecto SENA – IE Técnica Departamental Pijiño del Carmen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
        ListenableBuilder(
          listenable: Auth.instancia,
          builder: (_, __) {
            final u = Auth.instancia.actual;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Paleta.atardecer,
                  foregroundColor: Colors.white,
                  child: Text(u == null || u.nombre.isEmpty ? '?' : u.nombre.substring(0, 1).toUpperCase()),
                ),
                title: Text(u?.nombre ?? 'Invitado',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(u == null ? 'Crea una cuenta para enviar aportes y guardar favoritos' : '${u.perfil} · ${u.correo}'),
                trailing: TextButton(
                  onPressed: Auth.instancia.salir,
                  child: Text(u == null ? 'Ingresar' : 'Salir'),
                ),
              ),
            );
          },
        ),
        _item(Icons.info_outline, 'Información del municipio',
            () => ir(const InfoMunicipioScreen())),
        _item(Icons.event, 'Fiestas y eventos', () => ir(const EventosScreen())),
        _item(Icons.public, 'Redes sociales y enlaces',
            () => ir(const EnlacesScreen())),
        _item(Icons.phone, 'Contactos de interés',
            () => ir(const ContactosScreen())),
        _item(Icons.volunteer_activism, 'Envía tu aporte',
            () => ir(const AporteScreen())),
        _item(Icons.favorite_border, 'Mis favoritos',
            () => ir(const FavoritosScreen())),
        const Divider(),
        _item(Icons.admin_panel_settings_outlined, 'Panel administrativo',
            () => ir(const AdminScreen())),
      ]),
    );
  }

  Widget _item(IconData i, String t, VoidCallback onTap) => ListTile(
        leading: Icon(i, color: Paleta.atardecer),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

// ---------------------------------------------------------------------------

class InfoMunicipioScreen extends StatefulWidget {
  const InfoMunicipioScreen({super.key});

  @override
  State<InfoMunicipioScreen> createState() => _InfoMunicipioScreenState();
}

class _InfoMunicipioScreenState extends State<InfoMunicipioScreen> {
  final _wiki = ApiWikipedia.resumen();

  @override
  Widget build(BuildContext context) {
    final m = Repositorio.instancia.datos!.municipio;
    String fmt(num? n) => n == null
        ? '—'
        : n.toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final datos = <(String, String)>[
      ('Departamento', '${m['departamento'] ?? 'Magdalena'}'),
      ('Población', '${fmt(m['poblacion'])} hab.'),
      ('Superficie', '${m['superficie_km2'] ?? '—'} km²'),
      ('Altitud', '${m['altitud_m'] ?? '—'} m s. n. m.'),
      ('Municipio desde', '26 de marzo de 1996'),
      ('Distancia a Santa Marta', '${m['distancia_santa_marta_km'] ?? '—'} km'),
      ('Alcalde', '${m['alcalde'] ?? '—'}'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pijiño del Carmen')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Column(
            children: datos
                .map((p) => ListTile(
                      dense: true,
                      title: Text(p.$1,
                          style: TextStyle(color: Colors.grey.shade600)),
                      trailing: SizedBox(
                        width: 190,
                        child: Text(p.$2,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text('Corregimientos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List<String>.from(m['corregimientos'] ?? const [])
              .map((c) => Chip(label: Text(c)))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Economía', style: Theme.of(context).textTheme.titleMedium),
        Text('${m['economia'] ?? ''}', style: const TextStyle(height: 1.5)),
        const SizedBox(height: 16),
        Text('Cómo llegar', style: Theme.of(context).textTheme.titleMedium),
        for (final r in (m['como_llegar'] as List? ?? const []))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                r['modo'] == 'Aéreo'
                    ? Icons.flight
                    : r['modo'] == 'Fluvial'
                        ? Icons.directions_boat
                        : Icons.directions_car,
                color: Paleta.cienaga),
            title: Text(r['modo']),
            subtitle: Text(r['detalle']),
          ),
        const SizedBox(height: 16),
        Text('En Wikipedia (en vivo)',
            style: Theme.of(context).textTheme.titleMedium),
        FutureBuilder<ResumenWiki>(
          future: _wiki,
          builder: (_, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator());
            }
            if (s.hasError) {
              return const Text('No disponible sin conexión.');
            }
            final w = s.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.extracto, style: const TextStyle(height: 1.5)),
                TextButton(
                    onPressed: () => abrirEnlace(context, w.url),
                    child: const Text('Leer artículo completo')),
              ],
            );
          },
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

class EnlacesScreen extends StatelessWidget {
  const EnlacesScreen({super.key});

  static const _grupos = {
    'red_social': 'Redes sociales',
    'institucional': 'Institucional',
    'turismo': 'Turismo',
    'prensa': 'Prensa y memoria',
  };

  IconData _icono(Enlace e) {
    switch (e.red) {
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.smart_display;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
    }
    switch (e.tipo) {
      case 'turismo':
        return Icons.travel_explore;
      case 'prensa':
        return Icons.article;
      default:
        return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enlaces = Repositorio.instancia.datos!.enlaces;
    return Scaffold(
      appBar: AppBar(title: const Text('Redes y enlaces')),
      body: ListView(children: [
        for (final g in _grupos.entries) ...[
          Titulo(g.value),
          for (final e in enlaces.where((e) => e.tipo == g.key))
            ListTile(
              leading: Icon(_icono(e), color: Paleta.cienaga),
              title: Text(e.titulo),
              subtitle: Text(Uri.parse(e.url).host,
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => abrirEnlace(context, e.url),
            ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

class ContactosScreen extends StatelessWidget {
  const ContactosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Repositorio.instancia.datos!.contactos;
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de interés')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = cs[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (c.descripcion.isNotEmpty) Text(c.descripcion),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, children: [
                    if (c.telefono != null)
                      ActionChip(
                        avatar: const Icon(Icons.call, size: 18),
                        label: Text(c.telefono!),
                        onPressed: () => llamar(c.telefono!),
                      ),
                    if (c.telefono != null && c.telefono!.length == 10)
                      ActionChip(
                        avatar: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        onPressed: () => abrirWhatsApp(c.telefono!,
                            texto: 'Hola, te escribo desde la app Conecta con Pijiño.'),
                      ),
                    if (c.correo != null)
                      ActionChip(
                        avatar: const Icon(Icons.mail, size: 18),
                        label: const Text('Correo'),
                        onPressed: () => escribirCorreo(c.correo!,
                            asunto: 'App Conecta con Pijiño'),
                      ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class AporteScreen extends StatefulWidget {
  const AporteScreen({super.key});

  @override
  State<AporteScreen> createState() => _AporteScreenState();
}

class _AporteScreenState extends State<AporteScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _mensaje = TextEditingController();
  final _enlace = TextEditingController();
  String _tipo = 'Historia o relato';
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final u = Auth.instancia.actual;
    if (u != null) {
      _nombre.text = u.nombre;
      _contacto.text = u.telefono.isNotEmpty ? u.telefono : u.correo;
    }
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final repo = Repositorio.instancia;
    try {
      if (repo.firebaseActivo) {
        await repo.enviarAporte(
          nombre: _nombre.text.trim(),
          contacto: _contacto.text.trim(),
          tipo: _tipo,
          mensaje: _mensaje.text.trim(),
          enlace: _enlace.text.trim().isEmpty ? null : _enlace.text.trim(),
        );
      } else {
        // Sin Firebase: se envía por correo al equipo.
        await escribirCorreo('sergioandres2010114018@gmail.com',
            asunto: 'Aporte app Pijiño: $_tipo – ${_nombre.text}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Gracias! Tu aporte será revisado antes de publicarse.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Envía tu aporte')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Cuéntanos una historia, comparte una receta, corrige un dato o envía el enlace a tus fotos y videos. El equipo valida cada aporte con la comunidad antes de publicarlo.'),
          const SizedBox(height: 16),
          TextFormField(
              controller: _nombre,
              validator: req,
              decoration: const InputDecoration(labelText: 'Tu nombre')),
          TextFormField(
              controller: _contacto,
              validator: req,
              decoration:
                  const InputDecoration(labelText: 'Teléfono o correo')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo de aporte'),
            items: const [
              'Historia o relato',
              'Receta / gastronomía',
              'Fotos o videos',
              'Evento',
              'Emprendimiento local',
              'Corrección de un dato',
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          TextFormField(
              controller: _mensaje,
              validator: req,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Mensaje')),
          TextFormField(
              controller: _enlace,
              decoration: const InputDecoration(
                  labelText: 'Enlace a fotos/video (opcional)')),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: ListenableBuilder(
        listenable: Favoritos.instancia,
        builder: (_, __) {
          final favs = d.contenidos
              .where((c) => Favoritos.instancia.es(c.id))
              .toList();
          if (favs.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Toca el corazón en cualquier contenido para guardarlo aquí.',
                  textAlign: TextAlign.center),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => TarjetaContenido(
              contenido: favs[i],
              portada: favs[i].imagenes.isEmpty
                  ? null
                  : d.medios[favs[i].imagenes.first],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetalleScreen(favs[i]))),
            ),
          );
        },
      ),
    );
  }
}
