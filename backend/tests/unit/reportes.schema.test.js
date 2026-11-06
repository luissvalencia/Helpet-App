const {
  crearReporteSchema,
  listarCercanosQuerySchema,
} = require("../../src/schemas/reportes.schema");

describe("crearReporteSchema", () => {
  const base = {
    tipo: "perdida",
    mascota: { nombre: "Firulais", especie: "Perro" },
    fotoUrl: "https://firebasestorage.googleapis.com/v0/b/helpet-app-503fd.firebasestorage.app/o/reportes%2Fu%2Ffoto.jpg?alt=media",
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

describe("crearReporteSchema: datos basura", () => {
  const base = {
    tipo: "perdida",
    mascota: { nombre: "Firulais", especie: "Perro" },
    fotoUrl:
      "https://firebasestorage.googleapis.com/v0/b/helpet-app-503fd.firebasestorage.app/o/reportes%2Fu%2Ffoto.jpg?alt=media",
    ubicacion: { lat: 2.44, lng: -76.6 },
  };

  it("rechaza un nombre de solo espacios", () => {
    const result = crearReporteSchema.safeParse({ ...base, mascota: { nombre: "   ", especie: "Perro" } });
    expect(result.success).toBe(false);
  });

  it("recorta los espacios de los textos", () => {
    const result = crearReporteSchema.safeParse({ ...base, mascota: { nombre: "  Toby ", especie: "Perro" } });
    expect(result.data.mascota.nombre).toBe("Toby");
  });

  it("rechaza una descripción excesivamente larga", () => {
    const result = crearReporteSchema.safeParse({
      ...base,
      mascota: { nombre: "Toby", especie: "Perro", descripcion: "a".repeat(501) },
    });
    expect(result.success).toBe(false);
  });

  it("rechaza coordenadas imposibles", () => {
    expect(crearReporteSchema.safeParse({ ...base, ubicacion: { lat: 200, lng: -76.6 } }).success).toBe(false);
    expect(crearReporteSchema.safeParse({ ...base, ubicacion: { lat: 2.4, lng: -500 } }).success).toBe(false);
  });

  it("rechaza fotos que no vienen del Storage de Helpet", () => {
    const result = crearReporteSchema.safeParse({ ...base, fotoUrl: "https://example.com/foto.jpg" });
    expect(result.success).toBe(false);
  });

  it("rechaza un radio de búsqueda negativo o gigante", () => {
    expect(listarCercanosQuerySchema.safeParse({ lat: "2.4", lng: "-76.6", radioKm: "-5" }).success).toBe(false);
    expect(listarCercanosQuerySchema.safeParse({ lat: "2.4", lng: "-76.6", radioKm: "100000" }).success).toBe(false);
  });
});
