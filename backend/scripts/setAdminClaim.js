// Script manual para asignar el rol admin a un usuario existente.
// Uso: node scripts/setAdminClaim.js <uid>
require("dotenv").config();
const { auth, firestore } = require("../src/config/firebase");

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    console.error("Uso: node scripts/setAdminClaim.js <uid>");
    process.exit(1);
  }

  await auth.setCustomUserClaims(uid, { rol: "admin" });
  await firestore.collection("users").doc(uid).update({ rol: "admin" });

  console.log(`Usuario ${uid} ahora tiene rol admin (custom claim + Firestore).`);
  console.log("El usuario debe volver a iniciar sesión para que el ID token incluya el claim actualizado.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
