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

describe("Centro de notificaciones in-app", () => {
  it("guarda una notificación al confirmar y se puede listar y marcar como leída", async () => {
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

    const coincidenciaRef = await firestore.collection("coincidencias").add({
      reporteIdA: reportePerdida.body.id,
      reporteIdB: reporteEncontrada.body.id,
      similitud: 0.82,
      estado: "pendiente",
      confirmadoPor: [],
      creadoEn: new Date(),
    });

    // Sin fcmToken registrado: el push falla en silencio, pero la
    // notificación in-app debe quedar guardada de todas formas.
    const confirmacion = await request(app)
      .post(`/coincidencias/${coincidenciaRef.id}/confirmar`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(confirmacion.status).toBe(200);

    // Ambos reportes usan las mismas coordenadas de prueba, así que
    // notificarReportesCercanos (US-20, fire-and-forget) puede además
    // avisarles del reporte del otro — eso es correcto, no un efecto
    // secundario a evitar. Se filtra por tipo en vez de asumir un arreglo
    // de longitud exacta, para no depender de esa carrera.
    const listaAvistador = await request(app)
      .get("/notificaciones")
      .set("Authorization", `Bearer ${avistador.idToken}`);
    expect(listaAvistador.status).toBe(200);
    const notifCoincidencia = listaAvistador.body.find((n) => n.tipo === "coincidencia_por_confirmar");
    expect(notifCoincidencia).toBeDefined();
    expect(notifCoincidencia.leida).toBe(false);
    const notifId = notifCoincidencia.id;

    const listaDueno = await request(app)
      .get("/notificaciones")
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(listaDueno.body.some((n) => n.tipo === "coincidencia_por_confirmar")).toBe(false);

    const marcarLeida = await request(app)
      .post(`/notificaciones/${notifId}/marcar-leida`)
      .set("Authorization", `Bearer ${avistador.idToken}`);
    expect(marcarLeida.status).toBe(200);

    const marcarLeidaAjena = await request(app)
      .post(`/notificaciones/${notifId}/marcar-leida`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(marcarLeidaAjena.status).toBe(403);

    const releida = await request(app)
      .get("/notificaciones")
      .set("Authorization", `Bearer ${avistador.idToken}`);
    expect(releida.body.find((n) => n.id === notifId).leida).toBe(true);
  });

  it("POST /notificaciones/marcar-todas-leidas marca todas las propias", async () => {
    const usuario = await crearUsuarioDePrueba({ nombre: "Usuario" });
    await firestore.collection("users").doc(usuario.uid).set({
      nombre: "Usuario",
      email: usuario.email,
      telefono: "3000000003",
      rol: "dueno",
    });

    await firestore.collection("notificacionesUsuario").add({
      uid: usuario.uid,
      titulo: "Título 1",
      cuerpo: "Cuerpo 1",
      tipo: "nuevo_reporte",
      data: {},
      leida: false,
      creadoEn: new Date(),
    });
    await firestore.collection("notificacionesUsuario").add({
      uid: usuario.uid,
      titulo: "Título 2",
      cuerpo: "Cuerpo 2",
      tipo: "nuevo_reporte",
      data: {},
      leida: false,
      creadoEn: new Date(),
    });

    const respuesta = await request(app)
      .post("/notificaciones/marcar-todas-leidas")
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(respuesta.status).toBe(200);
    expect(respuesta.body.actualizadas).toBe(2);

    const lista = await request(app)
      .get("/notificaciones")
      .set("Authorization", `Bearer ${usuario.idToken}`);
    expect(lista.body.every((n) => n.leida === true)).toBe(true);
  });

  it("DELETE /notificaciones/:id borra solo si es propia", async () => {
    const dueno = await crearUsuarioDePrueba({ nombre: "Dueño" });
    const otro = await crearUsuarioDePrueba({ nombre: "Otro" });
    await firestore.collection("users").doc(dueno.uid).set({
      nombre: "Dueño",
      email: dueno.email,
      telefono: "3000000004",
      rol: "dueno",
    });

    const notifRef = await firestore.collection("notificacionesUsuario").add({
      uid: dueno.uid,
      titulo: "Título",
      cuerpo: "Cuerpo",
      tipo: "nuevo_reporte",
      data: {},
      leida: false,
      creadoEn: new Date(),
    });

    const borrarAjeno = await request(app)
      .delete(`/notificaciones/${notifRef.id}`)
      .set("Authorization", `Bearer ${otro.idToken}`);
    expect(borrarAjeno.status).toBe(403);

    const borrarPropio = await request(app)
      .delete(`/notificaciones/${notifRef.id}`)
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(borrarPropio.status).toBe(200);

    const lista = await request(app)
      .get("/notificaciones")
      .set("Authorization", `Bearer ${dueno.idToken}`);
    expect(lista.body).toHaveLength(0);
  });
});
