const { firestore, auth } = require("../config/firebase");

const usersCollection = firestore.collection("users");

async function getUserByUid(uid) {
  const doc = await usersCollection.doc(uid).get();
  if (!doc.exists) return null;
  return { uid: doc.id, ...doc.data() };
}

async function updateUser(uid, data) {
  const allowedFields = [
    "nombre",
    "telefono",
    "ciudad",
    "direccionReferencia",
    "fotoUrl",
    "fcmToken",
    "notifCoincidencias",
    "notifReportesCercanos",
  ];
  const updateData = {};
  for (const field of allowedFields) {
    if (data[field] !== undefined) updateData[field] = data[field];
  }
  await usersCollection.doc(uid).update(updateData);
  return getUserByUid(uid);
}

async function listUsers() {
  const snapshot = await usersCollection.get();
  return snapshot.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
}

async function eliminarUsuario(uid) {
  // Los reportes/mascotas/coincidencias que ya existen se conservan tal
  // cual (son historial, y reportes.mascota ya es un snapshot independiente
  // de la colección mascotas) — solo se borra la cuenta en sí.
  await usersCollection.doc(uid).delete();
  await auth.deleteUser(uid);
}

module.exports = { getUserByUid, updateUser, listUsers, eliminarUsuario };
