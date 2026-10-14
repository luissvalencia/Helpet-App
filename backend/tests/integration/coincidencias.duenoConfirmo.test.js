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

// Feedback de pruebas de usuario: quien reportó el avistamiento no debería
// ver el botón de "sí, que me contacte" hasta que el dueño (lado "perdida")
// ya haya confirmado de su lado. `duenoYaConfirmo` es lo que el frontend usa
// para decidir si mostrar esa acción.
describe("GET /reportes/:id/coincidencias expone duenoYaConfirmo", () => {
  it("es false para ambos lados hasta que el dueño confirma, luego true para ambos", async () => {
    const dueno = await crearUsuarioDePrueba({ nombre: "Dueño" });
    const avistador = await crearUsuarioDePrueba({ nombre: "Avistador" });

    await firestore.collection("users").doc(dueno.uid).set({
      nombre: "Dueño",
      email: dueno.email,
      telefono: "3000000001",
      rol: "dueno",
    });
    await firestore.collection("users").doc(avistador.uid).set({
      nombre: "Avistador",
      email: avistador.email,
      telefono: "3000000002",
      rol: "ciudadano",
    });

    const reportePerdida = await crearReporte(dueno.idToken, "perdida");
    const reporteEncontrada = await crearReporte(avistador.idToken, "encontrada");
    expect(reportePerdida.status).toBe(201);
    expect(reporteEncontrada.status).toBe(201);

    const coincidenciaRef = await firestore.collection("coincidencias").add({
      reporteIdA: reportePerdida.body.id,
      reporteIdB: reporteEncontrada.body.id,
      similitud: 0.82,
      estado: "pendiente",
      confirmadoPor: [],
      creadoEn: new Date(),
    });

    const antesDesdeAvistador = await request(app)
      .get(`/reportes/${reporteEncontrada.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${avistador.idToken}`);
    expect(antesDesdeAvistador.status).toBe(200);
    expect(antesDesdeAvistador.body[0].duenoYaConfirmo).toBe(false);

    const antesDesdeDueno = await request(app)
      .get(`/reportes/${reportePerdida.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(antesDesdeDueno.body[0].duenoYaConfirmo).toBe(false);

    const confirmacionDueno = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(confirmacionDueno.status).toBe(200);
    expect(confirmacionDueno.body.confirmada).toBe(false);

    const despuesDesdeAvistador = await request(app)
      .get(`/reportes/${reporteEncontrada.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${avistador.idToken}`);
    expect(despuesDesdeAvistador.body[0].duenoYaConfirmo).toBe(true);
    expect(despuesDesdeAvistador.body[0].yoConfirme).toBe(false);

    const despuesDesdeDueno = await request(app)
      .get(`/reportes/${reportePerdida.body.id}/coincidencias`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(despuesDesdeDueno.body[0].duenoYaConfirmo).toBe(true);
    expect(despuesDesdeDueno.body[0].yoConfirme).toBe(true);
  });
});
