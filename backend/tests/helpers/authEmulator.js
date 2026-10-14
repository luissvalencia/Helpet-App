const { auth } = require("../../src/config/firebase");

const PASSWORD_DE_PRUEBA = "Password123!";

async function crearUsuarioDePrueba(overrides = {}) {
  const email =
    overrides.email || `test-${Date.now()}-${Math.random().toString(36).slice(2)}@helpet.test`;

  const userRecord = await auth.createUser({
    email,
    password: PASSWORD_DE_PRUEBA,
    displayName: overrides.nombre || "Usuario de prueba",
  });

  if (overrides.rol) {
    await auth.setCustomUserClaims(userRecord.uid, { rol: overrides.rol });
  }

  const authEmulatorHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const respuesta = await fetch(
    `http://${authEmulatorHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: PASSWORD_DE_PRUEBA, returnSecureToken: true }),
    }
  );
  const data = await respuesta.json();
  if (!data.idToken) {
    throw new Error(`No se pudo obtener un idToken de prueba del Auth Emulator: ${JSON.stringify(data)}`);
  }

  return { uid: userRecord.uid, idToken: data.idToken, email };
}

module.exports = { crearUsuarioDePrueba };
