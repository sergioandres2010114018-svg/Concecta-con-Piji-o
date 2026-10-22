import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../services/repositorio.dart';
import '../theme.dart';

class Splash extends StatefulWidget {
  final Widget siguiente;
  const Splash({super.key, required this.siguiente});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await Future.wait([
      Repositorio.instancia.cargar(),
      Auth.instancia.restaurar(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => widget.siguiente,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/img/logo_crop.jpg', width: 220),
          const SizedBox(height: 18),
          Text('El corazón de Pijiño en cada atarraya',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Paleta.tierra, fontStyle: FontStyle.italic)),
          const SizedBox(height: 28),
          const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}
