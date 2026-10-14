const { haversineDistanceKm } = require("../../src/services/geo.service");

describe("haversineDistanceKm", () => {
  it("retorna 0 para el mismo punto", () => {
    const punto = { lat: 4.6, lng: -74.1 };
    expect(haversineDistanceKm(punto, punto)).toBeCloseTo(0, 6);
  });

  it("calcula ~240km en línea recta entre Bogotá y Medellín", () => {
    const bogota = { lat: 4.711, lng: -74.0721 };
    const medellin = { lat: 6.2442, lng: -75.5812 };
    const distancia = haversineDistanceKm(bogota, medellin);
    expect(distancia).toBeGreaterThan(200);
    expect(distancia).toBeLessThan(260);
  });

  it("es simétrica", () => {
    const a = { lat: 4.6, lng: -74.1 };
    const b = { lat: 4.65, lng: -74.05 };
    expect(haversineDistanceKm(a, b)).toBeCloseTo(haversineDistanceKm(b, a), 9);
  });
});
