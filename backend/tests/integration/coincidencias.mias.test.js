const request = require("supertest");
const app = require("../../src/app");
const { firestore } = require("../../src/config/firebase");
const { crearUsuarioDePrueba } = require("../helpers/authEmulator");

const crearReporte = (idToken, tipo, nombre) =>
  request(app)
    .post("/reportes")
    .set("Authorization", `Bearer ${idToken}`)
    .send({
      tipo,
      mascota: { nombre, especie: "Perro" },
      fotoUrl: "https://example.com/foto.jpg",
      ubicacion: { lat: 4.6, lng: -74.1 },
    });

describe("GET /coincidencias/mias", () => {
  it("agrega coincidencias de todos los reportes propios, sin importar el tipo", async () => {
    const yo = await crearUsuarioDePrueba({ nombre: "Yo" });
    const otro1 = await crearUsuarioDePrueba({ nombre: "Otro 1" });
    const otro2 = await crearUsuarioDePrueba({ nombre: "Otro 2" });
    const nombresPorUid = { [yo.uid]: "Yo", [otro1.uid]: "Otro 1", [otro2.uid]: "Otro 2" };

    for (const u of [yo, otro1, otro2]) {
      await firestore.collection("users").doc(u.uid).set({
        nombre: nombresPorUid[u.uid],
        email: u.email,
        telefono: "3000000000",
        rol: "dueno",
      });
    }

    const miReportePerdida = await crearReporte(yo.idToken, "perdida", "Firulais");
    const miReporteEncontrada = await crearReporte(yo.idToken, "encontrada", "Michi");
    const reporteOtro1 = await crearReporte(otro1.idToken, "encontrada", "Firulais look-alike");
    const reporteOtro2 = await crearReporte(otro2.idToken, "perdida", "Michi look-alike");
    expect(miReportePerdida.status).toBe(201);
    expect(miReporteEncontrada.status).toBe(201);

    await firestore.collection("coincidencias").add({
      reporteIdA: miReportePerdida.body.id,
      reporteIdB: reporteOtro1.body.id,
      similitud: 0.9,
      estado: "pendiente",
      confirmadoPor: [],
      creadoEn: new Date(),
    });
    await firestore.collection("coincidencias").add({
      reporteIdA: reporteOtro2.body.id,
      reporteIdB: miReporteEncontrada.body.id,
      similitud: 0.7,
      estado: "descartada",
      confirmadoPor: [],
      creadoEn: new Date(),
    });

    const respuesta = await request(app)
      .get("/coincidencias/mias")
      .set("Authorization", `Bearer ${yo.idToken}`);

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toHaveLength(1);
    expect(respuesta.body[0].miReporte.id).toBe(miReportePerdida.body.id);
    expect(respuesta.body[0].miReporte.tipo).toBe("perdida");
    expect(respuesta.body[0].reporte.propietarioNombre).toBe("Otro 1");
  });

  it("devuelve una lista vacía si el usuario no tiene reportes", async () => {
    const sinReportes = await crearUsuarioDePrueba({ nombre: "Sin reportes" });
    const respuesta = await request(app)
      .get("/coincidencias/mias")
      .set("Authorization", `Bearer ${sinReportes.idToken}`);

    expect(respuesta.status).toBe(200);
    expect(respuesta.body).toEqual([]);
  });
});
