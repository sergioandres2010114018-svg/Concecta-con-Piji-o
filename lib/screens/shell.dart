import 'package:flutter/material.dart';

import 'explorar.dart';
import 'galeria.dart';
import 'inicio.dart';
import 'mapa.dart';
import 'mas.dart';

/// Navegación principal con barra inferior.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  void irA(int i) => setState(() => _i = i);

  @override
  Widget build(BuildContext context) {
    final paginas = [
      InicioScreen(irA: irA),
      const ExplorarScreen(),
      const GaleriaScreen(),
      const MapaScreen(),
      const MasScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: irA,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explorar'),
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: 'Galería'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa'),
          NavigationDestination(
              icon: Icon(Icons.menu), label: 'Más'),
        ],
      ),
    );
  }
}
