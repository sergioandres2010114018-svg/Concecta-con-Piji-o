import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../theme.dart';

/// Imagen de red con caché, marcador de carga y respaldo si falla.
class ImagenRed extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? radio;
  const ImagenRed(this.url,
      {super.key, this.height, this.width, this.fit = BoxFit.cover, this.radio});

  @override
  Widget build(BuildContext context) {
    final respaldo = Container(
      height: height,
      width: width,
      color: Paleta.arena.withOpacity(.25),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Paleta.tierra),
    );
    final img = (url == null || url!.isEmpty)
        ? respaldo
        : CachedNetworkImage(
            imageUrl: url!,
            height: height,
            width: width,
            fit: fit,
            placeholder: (_, __) => Container(
                height: height,
                width: width,
                color: Paleta.arena.withOpacity(.15)),
            errorWidget: (_, __, ___) => respaldo,
          );
    return radio == null ? img : ClipRRect(borderRadius: radio!, child: img);
  }
}

class Titulo extends StatelessWidget {
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;
  const Titulo(this.texto, {super.key, this.accion, this.onAccion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 10),
      child: Row(children: [
        Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
        if (accion != null)
          TextButton(onPressed: onAccion, child: Text(accion!)),
      ]),
    );
  }
}

class TarjetaContenido extends StatelessWidget {
  final Contenido contenido;
  final Medio? portada;
  final VoidCallback onTap;
  const TarjetaContenido(
      {super.key, required this.contenido, this.portada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ImagenRed(portada?.miniatura, width: 108, height: 108),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contenido.titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(contenido.resumen,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Future<void> abrirEnlace(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
  }
}

Future<void> llamar(String telefono) =>
    launchUrl(Uri(scheme: 'tel', path: telefono));

Future<void> escribirCorreo(String correo, {String asunto = ''}) => launchUrl(
    Uri(scheme: 'mailto', path: correo, queryParameters: {'subject': asunto}));

Future<void> abrirWhatsApp(String telefono, {String texto = ''}) => launchUrl(
      Uri.parse(
          'https://wa.me/57$telefono?text=${Uri.encodeComponent(texto)}'),
      mode: LaunchMode.externalApplication,
    );
