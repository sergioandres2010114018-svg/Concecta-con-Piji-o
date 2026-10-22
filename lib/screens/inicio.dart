import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/apis.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'categoria.dart';
import 'detalle.dart';
import 'eventos.dart';

class InicioScreen extends StatefulWidget {
  final void Function(int) irA;
  const InicioScreen({super.key, required this.irA});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<Clima> _clima;

  @override
  void initState() {
    super.initState();
    _clima = ApiClima.obtener();
  }

  Future<void> _refrescar() async {
    setState(() => _clima = ApiClima.obtener());
    await Repositorio.instancia.cargar(forzarRed: true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final portada = d.medios['foto-cienaga-blog'] ?? d.fotos.firstOrNull;
    final proximos = d.eventosOrdenados.take(3).toList();
    final destacados = d.porCategoria('turismo').take(4).toList();

    return RefreshIndicator(
      onRefresh: _refrescar,
      child: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Paleta.noche,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Conecta con Pijiño',
                style: TextStyle(fontWeight: FontWeight.w800)),
            background: Stack(fit: StackFit.expand, children: [
              ImagenRed(portada?.miniatura),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC1B1712)],
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: _tarjetaClima()),
        SliverToBoxAdapter(
          child: Titulo('Descubre Pijiño',
              accion: 'Ver todo', onAccion: () => widget.irA(1)),
        ),
        SliverToBoxAdapter(child: _categorias(d)),
        SliverToBoxAdapter(
          child: Titulo('Próximas fiestas',
              accion: 'Calendario',
              onAccion: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EventosScreen()))),
        ),
        SliverList.list(
            children: proximos.map((e) => _filaEvento(context, e)).toList()),
        const SliverToBoxAdapter(child: Titulo('Lugares para visitar')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: destacados.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = destacados[i];
                final img = c.imagenes.isEmpty ? null : d.medios[c.imagenes.first];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetalleScreen(c))),
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImagenRed(img?.miniatura,
                            height: 150,
                            width: 220,
                            radio: BorderRadius.circular(14)),
                        const SizedBox(height: 8),
                        Text(c.titulo,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (d.noticias.isNotEmpty) const SliverToBoxAdapter(child: Titulo('Noticias')),
        SliverList.list(
          children: d.noticias
              .map((n) => ListTile(
                    leading: const Icon(Icons.newspaper, color: Paleta.cienaga),
                    title: Text(n.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${DateFormat.yMMMd('es_CO').format(n.fecha)} · ${n.resumen}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => abrirEnlace(context, n.url),
                  ))
              .toList(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              d.origen == 'local'
                  ? 'Mostrando datos guardados en la app (sin conexión a la base de datos).'
                  : d.origen == 'cache'
                      ? 'Mostrando la última copia descargada.'
                      : 'Datos actualizados desde la base de datos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tarjetaClima() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: Paleta.cienaga,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Clima>(
            future: _clima,
            builder: (_, s) {
              const blanco = TextStyle(color: Colors.white);
              if (s.connectionState != ConnectionState.done) {
                return const SizedBox(
                    height: 64,
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)));
              }
              if (s.hasError) {
                return const Text('Clima no disponible sin conexión.',
                    style: blanco);
              }
              final c = s.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 38)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c.temperatura.round()}°C · ${c.descripcion}',
                              style: blanco.copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          Text(
                              'Sensación ${c.sensacion.round()}° · Humedad ${c.humedad}% · Viento ${c.viento.round()} km/h',
                              style: blanco.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: c.dias
                        .map((dd) => Column(children: [
                              Text(DateFormat.E('es_CO').format(dd.fecha),
                                  style: blanco.copyWith(fontSize: 12)),
                              Text(emojiClima(dd.codigo)),
                              Text('${dd.max.round()}°/${dd.min.round()}°',
                                  style: blanco.copyWith(fontSize: 12)),
                            ]))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Text('Pijiño del Carmen · datos de Open-Meteo',
                      style: blanco.copyWith(fontSize: 10)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _categorias(DatosPijino d) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: d.categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = d.categorias[i];
          final col = colorHex(c.color);
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CategoriaScreen(c))),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: col.withOpacity(.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconoDe(c.icono), color: col, size: 30),
                  const SizedBox(height: 6),
                  Text(c.nombre,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaEvento(BuildContext context, Evento e) {
    final f = e.proximaFecha();
    final faltan =
        f == null ? null : f.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Paleta.atardecer.withOpacity(.15),
        child: Text(
          f == null ? '?' : (e.dia == null ? DateFormat.MMM('es_CO').format(f) : '${f.day}'),
          style: const TextStyle(
              color: Paleta.atardecer, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(e.lugar),
      trailing: faltan == null
          ? null
          : Text(faltan == 0 ? '¡Hoy!' : 'en $faltan d',
              style: const TextStyle(color: Paleta.tierra)),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const EventosScreen())),
    );
  }
}
