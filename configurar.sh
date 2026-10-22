#!/usr/bin/env bash
# Prepara el proyecto Flutter por primera vez (Linux/macOS o Git Bash en Windows).
# Genera las carpetas android/ e ios/, agrega permisos y descarga paquetes.
set -e

flutter create --org co.edu.sena --project-name conecta_pijino --platforms=android,ios .
# flutter create agrega una prueba de ejemplo que no aplica a esta app
rm -f test/widget_test.dart

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  # Permisos: internet (APIs, Firebase, mapas), cámara (subir fotos)
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.CAMERA"/>\n    <application#' "$MANIFEST"
  # Android 11+: permitir abrir navegador, teléfono, correo y WhatsApp
  sed -i.bak 's#</manifest>#    <queries>\n        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>\n        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>\n        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>\n    </queries>\n</manifest>#' "$MANIFEST"
  rm -f "$MANIFEST.bak"
fi

# Nombre visible de la app
sed -i.bak 's#android:label="conecta_pijino"#android:label="Conecta con Pijiño"#' "$MANIFEST" && rm -f "$MANIFEST.bak"

# minSdk 23 (requerido por Firebase)
GRADLE=$(ls android/app/build.gradle* | head -1)
sed -i.bak 's#minSdk = flutter.minSdkVersion#minSdk = 23#; s#minSdkVersion flutter.minSdkVersion#minSdkVersion 23#' "$GRADLE" && rm -f "$GRADLE.bak"

flutter pub get
dart run flutter_launcher_icons
echo ""
echo "✔ Proyecto listo. Ejecuta: flutter run"
echo "  Para conectar Firebase: flutterfire configure  (ver README.md)"
