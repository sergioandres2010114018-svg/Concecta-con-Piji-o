// ARCHIVO DE MARCADOR DE POSICIÓN.
//
// Reemplázalo ejecutando en la raíz del proyecto:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<tu-proyecto-firebase>
//
// FlutterFire generará este archivo con las claves reales. Mientras tanto la
// app funciona en "modo sin conexión" con los datos de assets/data/pijino.json.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'REEMPLAZAR',
        appId: 'REEMPLAZAR',
        messagingSenderId: 'REEMPLAZAR',
        projectId: 'REEMPLAZAR',
        storageBucket: 'REEMPLAZAR',
      );
}
