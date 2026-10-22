import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/models.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';

/// Galería multimedia: fotos (Storage o enlaces) y videos (YouTube o Storage).
class GaleriaScreen extends StatelessWidget {
  const GaleriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Galería'),
          bottom: TabBar(tabs: [
            Tab(text: 'Fotos (${d.fotos.length})'),
            Tab(text: 'Videos (${d.videos.length})'),
          ]),
        ),
        body: TabBarView(children: [
          GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: d.fotos.length,
            itemBuilder: (_, i) {
              final f = d.fotos[i];
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => VisorFoto(f))),
                child: Hero(
                  tag: f.id,
                  child: ImagenRed(f.miniatura, radio: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: d.videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final v = d.videos[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ReproductorVideo(v))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(alignment: Alignment.center, children: [
                        AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ImagenRed(v.miniatura)),
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.play_arrow,
                              color: Colors.white, size: 34),
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(v.credito,
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class VisorFoto extends StatelessWidget {
  final Medio foto;
  const VisorFoto(this.foto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(foto.titulo)),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: Hero(
                  tag: foto.id,
                  child: ImagenRed(foto.miniatura, fit: BoxFit.contain)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
                child: Text('Foto: ${foto.credito}',
                    style: const TextStyle(color: Colors.white70))),
            if (foto.fuente != null)
              TextButton(
                  onPressed: () => abrirEnlace(context, foto.fuente!),
                  child: const Text('Ver fuente')),
          ]),
        ),
      ]),
    );
  }
}

class ReproductorVideo extends StatefulWidget {
  final Medio video;
  const ReproductorVideo(this.video, {super.key});

  @override
  State<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends State<ReproductorVideo> {
  YoutubePlayerController? _yt;

  @override
  void initState() {
    super.initState();
    if (widget.video.esYoutube) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: widget.video.youtube!,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      appBar: AppBar(title: Text(v.titulo, maxLines: 1)),
      body: ListView(children: [
        if (_yt != null)
          YoutubePlayer(controller: _yt!, aspectRatio: 16 / 9)
        else
          // Videos subidos a Firebase Storage: se abren con el reproductor
          // del sistema para no añadir otra dependencia pesada.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproducir video'),
                  onPressed: () => abrirEnlace(context, v.url ?? ''),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.titulo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Autor: ${v.credito}',
                  style: const TextStyle(color: Paleta.tierra)),
              if (v.esYoutube)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir en YouTube'),
                  onPressed: () => abrirEnlace(
                      context, 'https://www.youtube.com/watch?v=${v.youtube}'),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
