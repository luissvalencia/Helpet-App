const admin = require("firebase-admin");

// Tests de integración (ver backend/tests) apuntan a Firestore/Auth Emulator
// Suite seteando estas env vars antes de requerir este módulo — en ese modo
// no hace falta ninguna credencial real, solo el projectId.
const usandoEmuladores = Boolean(
  process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST
);

if (!admin.apps.length) {
  admin.initializeApp(
    usandoEmuladores
      ? { projectId: process.env.GCLOUD_PROJECT || "demo-helpet" }
      : {
          credential: admin.credential.applicationDefault(),
          storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
        }
  );
}

const auth = admin.auth();
const firestore = admin.firestore();
const storage = admin.storage();

module.exports = { admin, auth, firestore, storage };
