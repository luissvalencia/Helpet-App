jest.mock("../../src/config/firebase", () => ({ firestore: {} }));

const {
  calcularPrecision,
  calcularTiempoNotificacion,
} = require("../../src/services/metricas.service");

const ts = (ms) => ({ toMillis: () => ms });

describe("calcularPrecision", () => {
  it("usa solo las coincidencias resueltas (confirmadas + descartadas)", () => {
    const resultado = calcularPrecision([
      { estado: "confirmada" },
      { estado: "confirmada" },
      { estado: "confirmada" },
      { estado: "descartada" },
      { estado: "pendiente" },
    ]);
    expect(resultado.coincidenciasResueltas).toBe(4);
    expect(resultado.precisionObservada).toBeCloseTo(0.75);
    expect(resultado.tasaFalsosPositivos).toBeCloseTo(0.25);
  });

  it("devuelve null si todavía no hay coincidencias resueltas", () => {
    const resultado = calcularPrecision([{ estado: "pendiente" }]);
    expect(resultado.precisionObservada).toBeNull();
    expect(resultado.tasaFalsosPositivos).toBeNull();
  });
});

describe("calcularTiempoNotificacion", () => {
  it("promedia el tiempo entre la coincidencia y su notificación", () => {
    const creadoEn = new Map([
      ["c1", 1_000],
      ["c2", 10_000],
    ]);
    const resultado = calcularTiempoNotificacion(
      [
        { data: { coincidenciaId: "c1" }, creadoEn: ts(3_000) },
        { data: { coincidenciaId: "c2" }, creadoEn: ts(14_000) },
      ],
      creadoEn,
    );
    expect(resultado.notificacionesMedidas).toBe(2);
    expect(resultado.tiempoPromedioNotificacionSeg).toBeCloseTo(3);
    expect(resultado.tiempoMaximoNotificacionSeg).toBeCloseTo(4);
  });

  it("ignora notificaciones sin coincidencia conocida o sin fecha", () => {
    const resultado = calcularTiempoNotificacion(
      [
        { data: { coincidenciaId: "borrada" }, creadoEn: ts(5_000) },
        { data: { coincidenciaId: "c1" } },
      ],
      new Map([["c1", 1_000]]),
    );
    expect(resultado.notificacionesMedidas).toBe(0);
    expect(resultado.tiempoPromedioNotificacionSeg).toBeNull();
  });
});
