import 'dart:convert';

import 'package:http/http.dart' as http;

/// Integraciones con APIs públicas (sin API key).
///
/// - Open-Meteo: clima actual y pronóstico de Pijiño del Carmen.
/// - Wikipedia REST: resumen enciclopédico actualizado del municipio.
/// - YouTube oEmbed: título y autor de cualquier video que se agregue.

class Clima {
  final double temperatura;
  final double sensacion;
  final int humedad;
  final double viento;
  final int codigo;
  final List<DiaPronostico> dias;
  const Clima({
    required this.temperatura,
    required this.sensacion,
    required this.humedad,
    required this.viento,
    required this.codigo,
    required this.dias,
  });

  String get descripcion => describirCodigoClima(codigo);
  String get emoji => emojiClima(codigo);
}

class DiaPronostico {
  final DateTime fecha;
  final double max;
  final double min;
  final int codigo;
  final int probLluvia;
  const DiaPronostico(this.fecha, this.max, this.min, this.codigo, this.probLluvia);
}

class ApiClima {
  static const lat = 9.3333;
  static const lng = -74.45;

  static Future<Clima> obtener() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'America/Bogota',
      'forecast_days': '5',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Open-Meteo respondió ${r.statusCode}');
    }
    final j = jsonDecode(r.body);
    final c = j['current'];
    final d = j['daily'];
    final dias = <DiaPronostico>[];
    for (var i = 0; i < (d['time'] as List).length; i++) {
      dias.add(DiaPronostico(
        DateTime.parse(d['time'][i]),
        (d['temperature_2m_max'][i] as num).toDouble(),
        (d['temperature_2m_min'][i] as num).toDouble(),
        d['weather_code'][i] as int,
        (d['precipitation_probability_max'][i] as num?)?.toInt() ?? 0,
      ));
    }
    return Clima(
      temperatura: (c['temperature_2m'] as num).toDouble(),
      sensacion: (c['apparent_temperature'] as num).toDouble(),
      humedad: (c['relative_humidity_2m'] as num).toInt(),
      viento: (c['wind_speed_10m'] as num).toDouble(),
      codigo: c['weather_code'] as int,
      dias: dias,
    );
  }
}

class ResumenWiki {
  final String titulo;
  final String extracto;
  final String? imagen;
  final String url;
  const ResumenWiki(this.titulo, this.extracto, this.imagen, this.url);
}

class ApiWikipedia {
  static Future<ResumenWiki> resumen(
      [String pagina = 'Pijiño_del_Carmen']) async {
    final uri = Uri.parse(
        'https://es.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(pagina)}');
    final r = await http.get(uri, headers: {
      'User-Agent': 'ConectaPijino/1.0 (app educativa SENA)'
    }).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw Exception('Wikipedia ${r.statusCode}');
    final j = jsonDecode(r.body);
    return ResumenWiki(
      j['title'] ?? 'Pijiño del Carmen',
      j['extract'] ?? '',
      j['thumbnail']?['source'],
      j['content_urls']?['mobile']?['page'] ??
          'https://es.wikipedia.org/wiki/$pagina',
    );
  }
}

class InfoYoutube {
  final String titulo;
  final String autor;
  const InfoYoutube(this.titulo, this.autor);
}

class ApiYoutube {
  static Future<InfoYoutube?> info(String id) async {
    try {
      final uri = Uri.https('www.youtube.com', '/oembed', {
        'url': 'https://www.youtube.com/watch?v=$id',
        'format': 'json',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      return InfoYoutube(j['title'] ?? '', j['author_name'] ?? '');
    } catch (_) {
      return null;
    }
  }
}

String describirCodigoClima(int c) {
  if (c == 0) return 'Despejado';
  if (c <= 2) return 'Parcialmente nublado';
  if (c == 3) return 'Nublado';
  if (c == 45 || c == 48) return 'Neblina';
  if (c >= 51 && c <= 57) return 'Llovizna';
  if (c >= 61 && c <= 67) return 'Lluvia';
  if (c >= 80 && c <= 82) return 'Aguaceros';
  if (c >= 95) return 'Tormenta eléctrica';
  return 'Variable';
}

String emojiClima(int c) {
  if (c == 0) return '☀️';
  if (c <= 2) return '⛅';
  if (c == 3) return '☁️';
  if (c == 45 || c == 48) return '🌫️';
  if (c >= 51 && c <= 67) return '🌧️';
  if (c >= 80 && c <= 82) return '🌦️';
  if (c >= 95) return '⛈️';
  return '🌤️';
}
