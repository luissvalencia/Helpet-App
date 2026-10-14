const { firestore, admin } = require("../config/firebase");

const mascotasCollection = firestore.collection("mascotas");

async function crearMascota(data, uid) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const mascota = {
    uid,
    nombre: data.nombre,
    especie: data.especie,
    raza: data.raza || "",
    color: data.color || "",
    descripcion: data.descripcion || "",
    fotoUrl: data.fotoUrl || null,
    creadoEn: now,
    actualizadoEn: now,
  };
  const docRef = await mascotasCollection.add(mascota);
  const doc = await docRef.get();
  return { id: doc.id, ...doc.data() };
}

async function listarMascotasPropias(uid) {
  const snapshot = await mascotasCollection.where("uid", "==", uid).get();
  return snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => (b.creadoEn?.toMillis?.() ?? 0) - (a.creadoEn?.toMillis?.() ?? 0));
}

async function getMascotaById(id) {
  const doc = await mascotasCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function actualizarMascota(id, uid, data) {
  const mascota = await getMascotaById(id);
  if (!mascota) return { error: "not_found" };
  if (mascota.uid !== uid) return { error: "forbidden" };

  const allowedFields = ["nombre", "especie", "raza", "color", "descripcion", "fotoUrl"];
  const updateData = { actualizadoEn: admin.firestore.FieldValue.serverTimestamp() };
  for (const field of allowedFields) {
    if (data[field] !== undefined) updateData[field] = data[field];
  }

  await mascotasCollection.doc(id).update(updateData);
  return { mascota: await getMascotaById(id) };
}

async function eliminarMascota(id, uid) {
  const mascota = await getMascotaById(id);
  if (!mascota) return { error: "not_found" };
  if (mascota.uid !== uid) return { error: "forbidden" };

  await mascotasCollection.doc(id).delete();
  return { ok: true };
}

module.exports = {
  crearMascota,
  listarMascotasPropias,
  getMascotaById,
  actualizarMascota,
  eliminarMascota,
};
