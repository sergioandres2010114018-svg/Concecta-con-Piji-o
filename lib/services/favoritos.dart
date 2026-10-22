import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoritos guardados en el teléfono (no requiere cuenta).
class Favoritos extends ChangeNotifier {
  Favoritos._();
  static final Favoritos instancia = Favoritos._();
  static const _key = 'favoritos_v1';

  final Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> cargar() async {
    final p = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(p.getStringList(_key) ?? const []);
    notifyListeners();
  }

  bool es(String id) => _ids.contains(id);

  Future<void> alternar(String id) async {
    _ids.contains(id) ? _ids.remove(id) : _ids.add(id);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _ids.toList());
  }
}
