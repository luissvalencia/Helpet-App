const request = require("supertest");
const app = require("../../src/app");
const { firestore } = require("../../src/config/firebase");
const { crearUsuarioDePrueba } = require("../helpers/authEmulator");

const crearReporte = (idToken, tipo) =>
  request(app)
    .post("/reportes")
    .set("Authorization", `Bearer ${idToken}`)
    .send({
      tipo,
      mascota: { nombre: "Firulais", especie: "Perro" },
      fotoUrl: "https://example.com/foto.jpg",
      ubicacion: { lat: 4.6, lng: -74.1 },
    });

describe("GET /reportes/:id/coincidencias solo para el dueño del reporte", () => {
  it("permite al dueño y bloquea al otro lado del match y a un tercero", async () => {
    const duenoA = await crearUsuarioDePrueba({ nombre: "Dueño A" });
    const duenoB = await crearUsuarioDePrueba({ nombre: "Dueño B" });

    await firestore.collection("users").doc(duenoA.uid).set({
      nombre: "Dueño A",
      email: duenoA.email,
      telefono: "3000000001",
      rol: "dueno",
    });
    await firestore.collection("users").doc(duenoB.uid).set({
      nombre: "Dueño B",
      email: duenoB.email,
      telefono: "3000000002",
      rol: "dueno",
    });

    const reporteA = await crearReporte(duenoA.idToken, "perdida");
    const reporteB = await crearReporte(duenoB.idToken, "encontrada");
    expect(reporteA.status).toBe(201);
    expect(reporteB.status).toBe(201);

    await firestore.collection("coincidencias").add({
      reporteIdA: reporteA.body.id,
      reporteIdB: reporteB.body.id,
      similitud: 0.82,
      estado: "pendiente",
      confirmadoPor: [],
      creadoEn: new Date(),
    });

    const comoDueno = await request(app)
      .get(`/reportes/${reporteA.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${duenoA.idToken}`);
    expect(comoDueno.status).toBe(200);
    expect(comoDueno.body).toHaveLength(1);
    expect(comoDueno.body[0].reporte.propietarioNombre).toBe("Dueño B");

    const otroLadoDelMatch = await request(app)
      .get(`/reportes/${reporteA.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${duenoB.idToken}`);
    expect(otroLadoDelMatch.status).toBe(403);

    const intruso = await crearUsuarioDePrueba({ nombre: "Intruso" });
    const comoIntruso = await request(app)
      .get(`/reportes/${reporteA.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${intruso.idToken}`);
    expect(comoIntruso.status).toBe(403);
  });
});
