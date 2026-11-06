const { validarFotoDeMascota } = require("../../src/services/aiService.service");

const FOTO = "https://firebasestorage.googleapis.com/v0/b/helpet-app-503fd.firebasestorage.app/o/x.jpg";

function respuesta(status, body) {
  return { status, ok: status >= 200 && status < 300, json: async () => body };
}

describe("validarFotoDeMascota", () => {
  const fetchOriginal = global.fetch;
  afterEach(() => {
    global.fetch = fetchOriginal;
  });

  it("rechaza una foto sin perro ni gato (ej. una imagen de texto)", async () => {
    global.fetch = jest.fn().mockResolvedValue(respuesta(200, { esMascota: false, especieDetectada: null }));
    await expect(validarFotoDeMascota(FOTO, "Perro")).rejects.toMatchObject({
      status: 422,
      codigo: "foto_sin_mascota",
    });
  });

  it("rechaza un archivo que no es imagen", async () => {
    global.fetch = jest.fn().mockResolvedValue(respuesta(422, { detail: "x" }));
    await expect(validarFotoDeMascota(FOTO, "Perro")).rejects.toMatchObject({ codigo: "foto_invalida" });
  });

  it("advierte si la especie detectada no es la elegida", async () => {
    global.fetch = jest.fn().mockResolvedValue(respuesta(200, { esMascota: true, especieDetectada: "Gato" }));
    await expect(validarFotoDeMascota(FOTO, "Perro")).rejects.toMatchObject({ codigo: "especie_distinta" });
  });

  it("deja pasar la especie distinta si el usuario ya la confirmó", async () => {
    global.fetch = jest.fn().mockResolvedValue(respuesta(200, { esMascota: true, especieDetectada: "Gato" }));
    await expect(validarFotoDeMascota(FOTO, "Perro", { aceptarEspecieDistinta: true })).resolves.toBeUndefined();
  });

  it("acepta una mascota de la especie elegida o ambigua", async () => {
    global.fetch = jest.fn().mockResolvedValue(respuesta(200, { esMascota: true, especieDetectada: "Perro" }));
    await expect(validarFotoDeMascota(FOTO, "Perro")).resolves.toBeUndefined();
    global.fetch = jest.fn().mockResolvedValue(respuesta(200, { esMascota: true, especieDetectada: null }));
    await expect(validarFotoDeMascota(FOTO, "Gato")).resolves.toBeUndefined();
  });

  it("no bloquea al usuario si el ai-service no responde", async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error("ECONNREFUSED"));
    await expect(validarFotoDeMascota(FOTO, "Perro")).resolves.toBeUndefined();
    global.fetch = jest.fn().mockResolvedValue(respuesta(401, {}));
    await expect(validarFotoDeMascota(FOTO, "Perro")).resolves.toBeUndefined();
  });
});
