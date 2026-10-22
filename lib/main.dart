import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'services/auth.dart';
import 'services/favoritos.dart';
import 'services/repositorio.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');

  if (firebaseConfigurado) {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      Repositorio.instancia.firebaseActivo = true;
    } catch (e) {
      debugPrint('Firebase no disponible, modo local: $e');
    }
  }
  await Favoritos.instancia.cargar();
  runApp(const ConectaPijinoApp());
}

class ConectaPijinoApp extends StatelessWidget {
  const ConectaPijinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conecta con Pijiño',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      home: const Splash(siguiente: PuertaSesion()),
    );
  }
}

/// Muestra el login hasta que el usuario inicia sesión, se registra o entra
/// como invitado; al cerrar sesión vuelve al login.
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Auth.instancia,
      builder: (_, __) =>
          Auth.instancia.conSesion ? const Shell() : const LoginScreen(),
    );
  }
}
