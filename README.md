# APP-Conecta con Pijiño

> *"El corazón de Pijiño en cada atarraya"*

Aplicación móvil (Flutter + Firebase) que reúne la historia, cultura, gastronomía, sitios turísticos, fiestas, ambiente, galería de fotos y videos y enlaces de **Pijiño del Carmen, Magdalena**.

Proyecto formativo SENA – Técnico en Programación de Aplicaciones para Dispositivos Móviles · Ficha 3321831 · IE Técnica Departamental Pijiño del Carmen · Centro Acuícola y Agroindustrial de Gaira.

---

## 1. Qué incluye (requisitos del PMV)

| Requisito del formato | Dónde está en la app |
|---|---|
| Login y registro de usuarios | Pantalla con la foto de las letras de PIJIÑO de fondo; usuarios guardados en Firestore `usuarios/{uid}` (o en el teléfono en modo local) |
| Pantalla de inicio | `Inicio`: portada, clima en vivo, categorías, próximas fiestas, lugares, noticias |
| Información general del municipio | `Más › Información del municipio` (datos + resumen en vivo de Wikipedia) |
| Historia | `Explorar › Historia` |
| Cultura y tradiciones | `Explorar › Cultura y tradiciones` + `Personajes` |
| Gastronomía | `Explorar › Gastronomía` |
| Sitios turísticos | `Explorar › Sitios turísticos` + `Mapa` |
| Fiestas y eventos | `Inicio › Calendario` con cuenta regresiva |
| Galería multimedia | `Galería` (fotos con zoom + videos YouTube/Storage) |
| Información ambiental | `Explorar › Ambiente` |
| Contacto / información de interés | `Más › Contactos`, `Redes y enlaces`, `Envía tu aporte` |
| Mejoras propuestas | Panel administrativo, mapa interactivo, modo sin conexión, favoritos, compartir |

## 2. Conexiones a APIs y base de datos

| Servicio | Uso | Clave |
|---|---|---|
| **Cloud Firestore** | Base de datos de contenidos, eventos, medios, enlaces, aportes | Firebase |
| **Firebase Storage** | Fotos y videos subidos desde el panel | Firebase |
| **Firebase Auth** | Ingreso de administradores | Firebase |
| **Open-Meteo** | Clima actual y pronóstico de 5 días | No requiere |
| **Wikipedia REST** | Resumen enciclopédico actualizado | No requiere |
| **YouTube (iframe + oEmbed)** | Reproducir videos y autocompletar título/autor | No requiere |
| **OpenStreetMap** | Mapa de sitios turísticos | No requiere |
| **Google Maps (enlace)** | Botón "Cómo llegar" | No requiere |

**Modo sin conexión:** si no hay internet o Firebase aún no está configurado, la app usa la última copia descargada y, si no existe, la base de datos incluida en `assets/data/pijino.json`.

## 3. Base de datos (colecciones Firestore)

```
municipio/info        datos generales
categorias/{id}       historia, cultura, gastronomia, turismo, ambiente, personajes
contenidos/{id}       titulo, resumen, cuerpo, categoria, imagenes[], videos[], ubicacion, fuentes[]
eventos/{id}          titulo, mes, dia, lugar, descripcion, imagen, video
medios/{id}           tipo (foto|video), url | youtube, titulo, credito, fuente, categoria
enlaces/{id}          tipo (red_social|institucional|turismo|prensa), red, titulo, url
noticias/{id}         fecha, titulo, resumen, url
contactos/{id}        titulo, telefono, correo, descripcion
usuarios/{uid}        nombre, correo, telefono, perfil, rol, creado (contraseña en Firebase Auth)
aportes/{id}          enviados por la comunidad; estado pendiente → validado/descartado
```

La semilla trae **25 contenidos, 13 eventos, 12 fotos, 10 videos y 14 enlaces** reunidos de fuentes públicas (Wikipedia, blog *Historias del Magdalena*, La Guía Turística, El Informador, El Espectador, Listín Diario, páginas de Facebook de la Alcaldía y canales de YouTube). Cada contenido guarda sus fuentes.

## 4. Obtener el APK sin instalar nada (GitHub Actions)

1. Crea una cuenta en <https://github.com> y un repositorio nuevo (por ejemplo `conecta-pijino`).
2. En el repositorio: **Add file › Upload files** y arrastra TODO el contenido de esta carpeta (incluida la carpeta oculta `.github`). Si el navegador no muestra `.github`, sube el proyecto con GitHub Desktop.
3. Pulsa **Commit changes**. GitHub empieza a compilar solo.
4. Ve a la pestaña **Actions › Compilar APK**: tarda unos 6–10 minutos.
5. Cuando termine (círculo verde), descarga `conecta-pijino.apk` desde **Releases** (columna derecha del repositorio) o desde **Artifacts** en la ejecución.
6. Pásalo al celular Android, ábrelo y permite *instalar apps de origen desconocido*.

Cada vez que subas un cambio se genera un APK nuevo.

## 5. Puesta en marcha en tu computador

Requisitos: Flutter 3.27+ y Android Studio.

```bash
cd conecta_pijino
bash configurar.sh        # genera android/ios, permisos, ícono y paquetes
flutter run               # ya funciona en modo local
```

### Conectar Firebase
1. Crear proyecto en <https://console.firebase.google.com>.
2. Activar **Firestore**, **Storage** y **Authentication → Correo/contraseña**.
3. `dart pub global activate flutterfire_cli` y luego `flutterfire configure`.
4. En `lib/config.dart` cambiar `firebaseConfigurado` a `true`.
5. Publicar reglas: `firebase deploy --only firestore:rules,storage` (editar el correo admin en las reglas).
6. Crear el usuario administrador en Authentication.
7. Cargar la base de datos: en la app `Más › Panel administrativo › Nuevo contenido › Sembrar base de datos`, o con `node scripts/seed_firestore.js`.

### Generar el APK
```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## 6. Estructura

```
lib/
  main.dart                 arranque, Firebase opcional
  theme.dart                paleta del logo (atardecer, arena, tierra, ciénaga)
  models/models.dart        modelos de datos
  services/repositorio.dart Firestore + caché + JSON local, subida a Storage
  services/apis.dart        Open-Meteo, Wikipedia, YouTube oEmbed
  services/favoritos.dart
  screens/                  splash, shell, inicio, explorar, categoria, detalle,
                            galeria, mapa, eventos, mas, admin
assets/data/pijino.json     base de datos semilla
firestore.rules / storage.rules
scripts/seed_firestore.js
test/modelos_test.dart
```

## 7. Pendientes de validación en campo
- Las coordenadas de los sitios están marcadas como **aproximadas**: tomarlas con GPS en cada lugar y actualizarlas desde el panel.
- Fotos y videos de terceros se enlazan con crédito a su autor. Para la versión final, conseguir autorización o reemplazarlas por material propio subido desde el panel.
- Confirmar fechas de los festivales sin día fijo (Duque Palomino, Maíz, Integración Pijiñera) con la Casa de la Cultura.
