const {
  crearReporteSchema,
  listarCercanosQuerySchema,
} = require("../../src/schemas/reportes.schema");

describe("crearReporteSchema", () => {
  const base = {
    tipo: "perdida",
    mascota: { nombre: "Firulais", especie: "Perro" },
    fotoUrl: "https://example.com/foto.jpg",
    ubicacion: { lat: 4.6, lng: -74.1 },
  };

  it("acepta un reporte válido", () => {
    expect(crearReporteSchema.safeParse(base).success).toBe(true);
  });

  it("rechaza un tipo inválido", () => {
    const result = crearReporteSchema.safeParse({ ...base, tipo: "otro" });
    expect(result.success).toBe(false);
    expect(result.error.issues[0].message).toMatch(/perdida.*encontrada/);
  });

  it("rechaza una especie fuera del enum cerrado", () => {
    const result = crearReporteSchema.safeParse({
      ...base,
      mascota: { nombre: "Firulais", especie: "Loro" },
    });
    expect(result.success).toBe(false);
  });

  it("rechaza 'Otro': el alcance es solo perros y gatos", () => {
    const result = crearReporteSchema.safeParse({
      ...base,
      mascota: { nombre: "Firulais", especie: "Otro" },
    });
    expect(result.success).toBe(false);
  });

  it("rechaza ubicación sin lat/lng numéricos", () => {
    const result = crearReporteSchema.safeParse({
      ...base,
      ubicacion: { lat: "no-numero", lng: -74.1 },
    });
    expect(result.success).toBe(false);
  });
});

describe("listarCercanosQuerySchema", () => {
  it("coacciona strings de query params a número y aplica default de radioKm", () => {
    const result = listarCercanosQuerySchema.safeParse({ lat: "4.6", lng: "-74.1" });
    expect(result.success).toBe(true);
    expect(result.data).toEqual({ lat: 4.6, lng: -74.1, radioKm: 10 });
  });

  it("rechaza si falta lat", () => {
    const result = listarCercanosQuerySchema.safeParse({ lng: "-74.1" });
    expect(result.success).toBe(false);
  });
});
