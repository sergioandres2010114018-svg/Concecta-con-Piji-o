// Carga la base de datos semilla (assets/data/pijino.json) en Firestore.
//
// Uso:
//   1. En la consola de Firebase: Configuración del proyecto > Cuentas de
//      servicio > Generar nueva clave privada. Guarda el archivo como
//      scripts/serviceAccount.json (NO lo subas a GitHub).
//   2. cd scripts && npm install firebase-admin
//   3. node seed_firestore.js
//
// También se puede sembrar desde la app: Más > Panel administrativo >
// Nuevo contenido > "Sembrar base de datos".

const admin = require('firebase-admin');
const path = require('path');
const datos = require(path.join(__dirname, '..', 'assets', 'data', 'pijino.json'));

admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccount.json')),
});
const db = admin.firestore();

const COLECCIONES = ['categorias', 'contenidos', 'eventos', 'medios',
  'enlaces', 'noticias', 'contactos'];

async function main() {
  await db.collection('municipio').doc('info').set(datos.municipio);
  let total = 0;
  for (const c of COLECCIONES) {
    const items = datos[c] || [];
    let batch = db.batch();
    let n = 0;
    for (const item of items) {
      batch.set(db.collection(c).doc(item.id), item);
      n++; total++;
      if (n === 400) { await batch.commit(); batch = db.batch(); n = 0; }
    }
    await batch.commit();
    console.log(`✔ ${c}: ${items.length}`);
  }
  console.log(`Listo: ${total} documentos cargados.`);
}

main().catch((e) => { console.error(e); process.exit(1); });
