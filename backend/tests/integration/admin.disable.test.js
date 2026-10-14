const request = require("supertest");
const app = require("../../src/app");
const { firestore } = require("../../src/config/firebase");
const { crearUsuarioDePrueba } = require("../helpers/authEmulator");

describe("PATCH /admin/users/:uid/disable", () => {
  it("revoca el token vigente del usuario deshabilitado, no solo marca el flag", async () => {
    const admin = await crearUsuarioDePrueba({ nombre: "Admin", rol: "admin" });
    const victima = await crearUsuarioDePrueba({ nombre: "Víctima" });

    await firestore.collection("users").doc(victima.uid).set({
      nombre: "Víctima",
      email: victima.email,
      rol: "dueno",
    });

    // El token de la víctima ya está emitido en este punto; debe dejar de
    // funcionar en cuanto el admin la deshabilite, no solo tras su expiración
    // natural (~1h).
    const antesDeDeshabilitar = await request(app)
      .get("/users/me")
      .set("Authorization", `Bearer ${victima.idToken}`);
    expect(antesDeDeshabilitar.status).toBe(200);

    // La revocación de Firebase Auth solo distingue tokens emitidos antes o
    // después del segundo en que se llama revokeRefreshTokens.
    await new Promise((resolve) => setTimeout(resolve, 1100));

    const respuestaDisable = await request(app)
      .patch(`/admin/users/${victima.uid}/disable`)
      .set("Authorization", `Bearer ${admin.idToken}`);
    expect(respuestaDisable.status).toBe(200);

    const despuesDeDeshabilitar = await request(app)
      .get("/users/me")
      .set("Authorization", `Bearer ${victima.idToken}`);
    expect(despuesDeDeshabilitar.status).toBe(401);
  });

  it("un usuario sin rol admin no puede deshabilitar a otros", async () => {
    const usuarioComun = await crearUsuarioDePrueba({ nombre: "Usuario común" });
    const otro = await crearUsuarioDePrueba({ nombre: "Otro" });

    const respuesta = await request(app)
      .patch(`/admin/users/${otro.uid}/disable`)
      .set("Authorization", `Bearer ${usuarioComun.idToken}`);
    expect(respuesta.status).toBe(403);
  });
});
