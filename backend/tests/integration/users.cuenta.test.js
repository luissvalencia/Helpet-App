const request = require("supertest");
const app = require("../../src/app");
const { firestore } = require("../../src/config/firebase");
const { crearUsuarioDePrueba } = require("../helpers/authEmulator");

describe("DELETE /users/me", () => {
  it("borra el doc de Firestore y el usuario de Firebase Auth del propio caller", async () => {
    const usuario = await crearUsuarioDePrueba({ nombre: "Se va a borrar" });
    await firestore.collection("users").doc(usuario.uid).set({
      nombre: "Se va a borrar",
      email: usuario.email,
      rol: "dueno",
    });

    const respuesta = await request(app)
      .delete("/users/me")
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(respuesta.status).toBe(204);

    const doc = await firestore.collection("users").doc(usuario.uid).get();
    expect(doc.exists).toBe(false);

    const siguienteLlamada = await request(app)
      .get("/users/me")
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(siguienteLlamada.status).toBe(401);
  });
});

describe("POST /users/:uid/reportar", () => {
  it("un usuario puede reportar a otro y el admin puede verlo en /admin/reportes-usuario", async () => {
    const admin = await crearUsuarioDePrueba({ nombre: "Admin", rol: "admin" });
    const reportante = await crearUsuarioDePrueba({ nombre: "Reportante" });
    const reportado = await crearUsuarioDePrueba({ nombre: "Reportado" });

    const respuesta = await request(app)
      .post(`/users/${reportado.uid}/reportar`)
      .set("Authorization", `Bearer ${reportante.idToken}`)
      .send({ motivo: "No se presentó a la cita para devolver la mascota" });
    expect(respuesta.status).toBe(201);
    expect(respuesta.body).toMatchObject({
      reportadoUid: reportado.uid,
      reportanteUid: reportante.uid,
      estado: "pendiente",
    });

    const listado = await request(app)
      .get("/admin/reportes-usuario")
      .set("Authorization", `Bearer ${admin.idToken}`);
    expect(listado.status).toBe(200);
    expect(listado.body.some((r) => r.id === respuesta.body.id)).toBe(true);
  });

  it("rechaza que alguien se reporte a sí mismo", async () => {
    const usuario = await crearUsuarioDePrueba({ nombre: "Solitario" });

    const respuesta = await request(app)
      .post(`/users/${usuario.uid}/reportar`)
      .set("Authorization", `Bearer ${usuario.idToken}`)
      .send({ motivo: "prueba" });
    expect(respuesta.status).toBe(400);
  });

  it("un usuario sin rol admin no puede ver /admin/reportes-usuario", async () => {
    const usuarioComun = await crearUsuarioDePrueba({ nombre: "Común" });

    const respuesta = await request(app)
      .get("/admin/reportes-usuario")
      .set("Authorization", `Bearer ${usuarioComun.idToken}`);
    expect(respuesta.status).toBe(403);
  });
});
