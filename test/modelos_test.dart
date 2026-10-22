import 'dart:convert';
import 'dart:io';

import 'package:conecta_pijino/models/models.dart';
import 'package:conecta_pijino/services/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DatosPijino d;

  setUpAll(() {
    final txt = File('assets/data/pijino.json').readAsStringSync();
    d = DatosPijino.fromJson(jsonDecode(txt), 'local');
  });

  test('la base de datos semilla carga todas las secciones del PMV', () {
    for (final cat in ['historia', 'cultura', 'gastronomia', 'turismo', 'ambiente']) {
      expect(d.porCategoria(cat), isNotEmpty, reason: 'falta $cat');
    }
    expect(d.eventos, isNotEmpty);
    expect(d.fotos, isNotEmpty);
    expect(d.videos, isNotEmpty);
    expect(d.enlaces, isNotEmpty);
    expect(d.contactos, isNotEmpty);
  });

  test('todas las referencias a medios existen', () {
    for (final c in d.contenidos) {
      for (final id in [...c.imagenes, ...c.videos]) {
        expect(d.medios.containsKey(id), isTrue, reason: '${c.id} -> $id');
      }
    }
  });

  test('próxima fecha de evento salta al año siguiente si ya pasó', () {
    const e = Evento(id: 'x', titulo: 'x', mes: 7, dia: 16, lugar: '', descripcion: '');
    expect(e.proximaFecha(DateTime(2026, 10, 22)), DateTime(2027, 7, 16));
    expect(e.proximaFecha(DateTime(2026, 7, 1)), DateTime(2026, 7, 16));
  });

  test('extrae el id de distintos enlaces de YouTube', () {
    expect(extraerIdYoutube('https://www.youtube.com/watch?v=WBT61vYY4I8'), 'WBT61vYY4I8');
    expect(extraerIdYoutube('https://youtu.be/k7QvwMrswA4'), 'k7QvwMrswA4');
    expect(extraerIdYoutube('https://www.youtube.com/shorts/VJ9pEaH4C7g'), 'VJ9pEaH4C7g');
    expect(extraerIdYoutube('no es un video'), isNull);
  });

  test('ida y vuelta JSON conserva los datos', () {
    final copia = DatosPijino.fromJson(
        jsonDecode(jsonEncode(d.toJson())), 'cache');
    expect(copia.contenidos.length, d.contenidos.length);
    expect(copia.medios.length, d.medios.length);
  });
}
