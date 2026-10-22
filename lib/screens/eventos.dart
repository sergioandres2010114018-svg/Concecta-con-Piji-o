import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'galeria.dart';

/// Calendario de fiestas y eventos ordenado por proximidad.
class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final eventos = d.eventosOrdenados;
    final hoy = DateUtils.dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Fiestas y eventos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventos.length,
        itemBuilder: (_, i) {
          final e = eventos[i];
          final f = e.proximaFecha();
          final img = e.imagen == null ? null : d.medios[e.imagen];
          final vid = e.video == null ? null : d.medios[e.video];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (img != null)
                  ImagenRed(img.miniatura, height: 140, width: double.infinity),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Fecha(e: e, f: f),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(e.lugar,
                                style: const TextStyle(color: Paleta.tierra)),
                            const SizedBox(height: 6),
                            Text(e.descripcion),
                            if (f != null && e.fechaExacta)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _faltan(f.difference(hoy).inDays),
                                  style: const TextStyle(
                                      color: Paleta.atardecer,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            if (vid != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                icon: const Icon(Icons.play_circle),
                                label: const Text('Ver video'),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ReproductorVideo(vid))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _faltan(int dias) {
    if (dias == 0) return '¡Es hoy!';
    if (dias == 1) return 'Mañana';
    return 'Faltan $dias días';
  }
}

class _Fecha extends StatelessWidget {
  final Evento e;
  final DateTime? f;
  const _Fecha({required this.e, required this.f});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Paleta.atardecer.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(
          f == null ? 'Por' : DateFormat.MMM('es_CO').format(f!).toUpperCase(),
          style: const TextStyle(
              color: Paleta.atardecer, fontWeight: FontWeight.w800, fontSize: 12),
        ),
        Text(
          f == null ? 'definir' : (e.dia == null ? '—' : '${f!.day}'),
          style: TextStyle(
              color: Paleta.noche,
              fontWeight: FontWeight.w800,
              fontSize: f == null ? 11 : 22),
        ),
      ]),
    );
  }
}
