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

describe("POST /coincidencias/:id/confirmar con dos cuentas reales distintas", () => {
  it("solo revela el contacto cuando AMBOS dueños confirman, y bloquea a terceros", async () => {
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

    // En producción esta coincidencia la crea el ai-service tras comparar
    // embeddings (US-13); aquí se siembra directo para probar el endpoint
    // de confirmación de forma aislada.
    const coincidenciaRef = await firestore.collection("coincidencias").add({
      reporteIdA: reporteA.body.id,
      reporteIdB: reporteB.body.id,
      similitud: 0.82,
      estado: "pendiente",
      confirmadoPor: [],
      creadoEn: new Date(),
    });

    const primeraConfirmacion = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${duenoA.idToken}`);
    expect(primeraConfirmacion.status).toBe(200);
    expect(primeraConfirmacion.body.confirmada).toBe(false);
    expect(primeraConfirmacion.body.contacto).toBeNull();

    const confirmarDeNuevo = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${duenoA.idToken}`);
    expect(confirmarDeNuevo.status).toBe(200);
    expect(confirmarDeNuevo.body.confirmada).toBe(false);

    const segundaConfirmacion = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${duenoB.idToken}`);
    expect(segundaConfirmacion.status).toBe(200);
    expect(segundaConfirmacion.body.confirmada).toBe(true);
    expect(segundaConfirmacion.body.contacto).toMatchObject({
      nombre: "Dueño A",
      telefono: "3000000001",
    });

    const intruso = await crearUsuarioDePrueba({ nombre: "Intruso" });
    const rechazo = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${intruso.idToken}`);
    expect(rechazo.status).toBe(403);
  });
});
