import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/repositorio.dart';
import '../widgets/comunes.dart';
import 'detalle.dart';

class CategoriaScreen extends StatelessWidget {
  final Categoria categoria;
  const CategoriaScreen(this.categoria, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final items = d.porCategoria(categoria.id);
    return Scaffold(
      appBar: AppBar(title: Text(categoria.nombre)),
      body: items.isEmpty
          ? const Center(child: Text('Aún no hay contenidos en esta sección.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = items[i];
                return TarjetaContenido(
                  contenido: c,
                  portada:
                      c.imagenes.isEmpty ? null : d.medios[c.imagenes.first],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetalleScreen(c))),
                );
              },
            ),
    );
  }
}
