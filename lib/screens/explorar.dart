import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'categoria.dart';
import 'detalle.dart';

/// Explorar: categorías + buscador sobre todos los contenidos.
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  String _q = '';

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úù]'), 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final q = _norm(_q);
    final resultados = q.isEmpty
        ? <Contenido>[]
        : d.contenidos
            .where((c) => _norm('${c.titulo} ${c.resumen} ${c.cuerpo}').contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar: bocachico, malecón, chandé…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          if (q.isNotEmpty) ...[
            Titulo('${resultados.length} resultado(s)'),
            for (final c in resultados)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: TarjetaContenido(
                  contenido: c,
                  portada: c.imagenes.isEmpty ? null : d.medios[c.imagenes.first],
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetalleScreen(c))),
                ),
              ),
          ] else ...[
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final cat in d.categorias)
                  _TarjetaCategoria(cat, d.porCategoria(cat.id), d),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaCategoria extends StatelessWidget {
  final Categoria cat;
  final List<Contenido> items;
  final DatosPijino d;
  const _TarjetaCategoria(this.cat, this.items, this.d);

  @override
  Widget build(BuildContext context) {
    final col = colorHex(cat.color);
    String? img;
    for (final c in items) {
      if (c.imagenes.isNotEmpty) {
        img = d.medios[c.imagenes.first]?.miniatura;
        break;
      }
    }
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => CategoriaScreen(cat))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(fit: StackFit.expand, children: [
          img == null ? Container(color: col.withOpacity(.2)) : ImagenRed(img),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [col.withOpacity(.15), col.withOpacity(.92)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(iconoDe(cat.icono), color: Colors.white),
                const SizedBox(height: 4),
                Text(cat.nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('${items.length} temas',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
