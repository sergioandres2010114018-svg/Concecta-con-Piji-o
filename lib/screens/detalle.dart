import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/favoritos.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'galeria.dart';
import 'mapa.dart';

class DetalleScreen extends StatelessWidget {
  final Contenido c;
  const DetalleScreen(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final fotos = c.imagenes.map((id) => d.medios[id]).whereType<Medio>().toList();
    final videos = c.videos.map((id) => d.medios[id]).whereType<Medio>().toList();
    final cat = d.categoria(c.categoria);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: fotos.isEmpty ? 120 : 280,
          pinned: true,
          actions: [
            ListenableBuilder(
              listenable: Favoritos.instancia,
              builder: (_, __) {
                final fav = Favoritos.instancia.es(c.id);
                return IconButton(
                  tooltip: 'Favorito',
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? Colors.redAccent : null),
                  onPressed: () => Favoritos.instancia.alternar(c.id),
                );
              },
            ),
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(
                  '${c.titulo} – Pijiño del Carmen\n\n${c.resumen}\n\nDescúbrelo en la app Conecta con Pijiño.'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: fotos.isEmpty
                ? Container(color: colorHex(cat?.color ?? '#BD6B2F').withOpacity(.2))
                : PageView(
                    children: fotos
                        .map((f) => GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => VisorFoto(f))),
                              child: ImagenRed(f.miniatura),
                            ))
                        .toList(),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(children: [
            if (cat != null)
              Text(cat.nombre.toUpperCase(),
                  style: TextStyle(
                      color: colorHex(cat.color),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 12)),
            const SizedBox(height: 6),
            Text(c.titulo, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(c.resumen,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Paleta.tierra)),
            const SizedBox(height: 14),
            Text(c.cuerpo, style: const TextStyle(fontSize: 16, height: 1.55)),
            if (c.ubicacion != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(c.ubicacion!.aprox
                    ? 'Ver en el mapa (ubicación aproximada)'
                    : 'Ver en el mapa'),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MapaScreen(enfocar: c))),
              ),
            ],
            if (videos.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Videos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final v in videos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ImagenRed(v.miniatura,
                      width: 96, height: 56, radio: BorderRadius.circular(8)),
                  title: Text(v.titulo, maxLines: 2),
                  subtitle: Text(v.credito),
                  trailing: const Icon(Icons.play_circle, color: Paleta.atardecer),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ReproductorVideo(v))),
                ),
            ],
            if (c.fuentes.where((f) => f.url.isNotEmpty).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Fuentes', style: Theme.of(context).textTheme.titleMedium),
              for (final f in c.fuentes.where((f) => f.url.isNotEmpty))
                TextButton.icon(
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(f.titulo, textAlign: TextAlign.left),
                  onPressed: () => abrirEnlace(context, f.url),
                ),
            ],
            const SizedBox(height: 20),
            Text(
              '¿Conoces más sobre este tema o tienes fotos? Envía tu aporte desde la sección "Más".',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ]),
        ),
      ]),
    );
  }
}
