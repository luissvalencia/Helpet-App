const request = require("supertest");
const app = require("../../src/app");
const { crearUsuarioDePrueba } = require("../helpers/authEmulator");

describe("Flujo de reportes (Firestore + Auth Emulator)", () => {
  let usuario;

  beforeAll(async () => {
    usuario = await crearUsuarioDePrueba({ nombre: "Dueño de prueba" });
  });

  it("crea, impide borrar activo, cierra y luego borra un reporte propio", async () => {
    const crear = await request(app)
      .post("/reportes")
      .set("Authorization", `Bearer ${usuario.idToken}`)
      .send({
        tipo: "perdida",
        mascota: { nombre: "Firulais", especie: "Perro" },
        fotoUrl: "https://example.com/foto.jpg",
        ubicacion: { lat: 4.6, lng: -74.1, direccionTexto: "Bogotá" },
      });

    expect(crear.status).toBe(201);
    expect(crear.body.estado).toBe("activo");
    const reporteId = crear.body.id;

    const borrarActivo = await request(app)
      .delete(`/reportes/${reporteId}`)
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(borrarActivo.status).toBe(400);

    const cerrar = await request(app)
      .post(`/reportes/${reporteId}/cerrar`)
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(cerrar.status).toBe(200);
    expect(cerrar.body.estado).toBe("cerrado");

    const borrar = await request(app)
      .delete(`/reportes/${reporteId}`)
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(borrar.status).toBe(204);

    const detalle = await request(app)
      .get(`/reportes/${reporteId}`)
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(detalle.status).toBe(404);
  });

  it("rechaza un body inválido con 400 antes de tocar Firestore", async () => {
    const res = await request(app)
      .post("/reportes")
      .set("Authorization", `Bearer ${usuario.idToken}`)
      .send({ tipo: "no-es-un-tipo-valido" });
    expect(res.status).toBe(400);
  });

  it("rechaza requests sin token con 401", async () => {
    const res = await request(app).get("/reportes/mios");
    expect(res.status).toBe(401);
  });
});
