import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/repositorio.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import 'detalle.dart';

/// Mapa interactivo con OpenStreetMap (sin API key).
class MapaScreen extends StatefulWidget {
  final Contenido? enfocar;
  const MapaScreen({super.key, this.enfocar});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  Contenido? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.enfocar;
  }

  @override
  Widget build(BuildContext context) {
    final d = Repositorio.instancia.datos!;
    final lugares = d.contenidos.where((c) => c.ubicacion != null).toList();
    final centro = _sel?.ubicacion != null
        ? LatLng(_sel!.ubicacion!.lat, _sel!.ubicacion!.lng)
        : LatLng((d.municipio['lat'] as num?)?.toDouble() ?? 9.3333,
            (d.municipio['lng'] as num?)?.toDouble() ?? -74.45);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Pijiño')),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: centro,
            initialZoom: widget.enfocar != null ? 15 : 13,
            onTap: (_, __) => setState(() => _sel = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'co.edu.sena.conecta_pijino',
            ),
            MarkerLayer(
              markers: lugares.map((c) {
                final activo = _sel?.id == c.id;
                return Marker(
                  point: LatLng(c.ubicacion!.lat, c.ubicacion!.lng),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => setState(() => _sel = c),
                    child: Icon(Icons.location_on,
                        size: activo ? 44 : 36,
                        color: activo ? Paleta.atardecer : Paleta.cienaga),
                  ),
                );
              }).toList(),
            ),
            const RichAttributionWidget(attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ]),
          ],
        ),
        if (_sel != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              child: ListTile(
                leading: ImagenRed(
                  _sel!.imagenes.isEmpty
                      ? null
                      : d.medios[_sel!.imagenes.first]?.miniatura,
                  width: 56,
                  height: 56,
                  radio: BorderRadius.circular(8),
                ),
                title: Text(_sel!.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    _sel!.ubicacion!.aprox
                        ? 'Ubicación aproximada · toca para ver'
                        : 'Toca para ver',
                    style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.directions),
                  tooltip: 'Cómo llegar',
                  onPressed: () => abrirEnlace(context,
                      'https://www.google.com/maps/dir/?api=1&destination=${_sel!.ubicacion!.lat},${_sel!.ubicacion!.lng}'),
                ),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DetalleScreen(_sel!))),
              ),
            ),
          ),
      ]),
    );
  }
}
