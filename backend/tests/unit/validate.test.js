const { z } = require("zod");
const validate = require("../../src/middlewares/validate");

function mockReqRes(body) {
  return { req: { body }, res: {}, next: jest.fn() };
}

describe("validate middleware", () => {
  const schema = z.object({ nombre: z.string().min(1, "nombre requerido") });

  it("deja pasar un body válido y normaliza req.body con los datos parseados", () => {
    const { req, res, next } = mockReqRes({ nombre: "Rex" });
    validate(schema)(req, res, next);
    expect(next).toHaveBeenCalledWith();
    expect(req.body).toEqual({ nombre: "Rex" });
  });

  it("llama next con un AppError 400 cuando el body es inválido", () => {
    const { req, res, next } = mockReqRes({ nombre: "" });
    validate(schema)(req, res, next);
    expect(next).toHaveBeenCalledTimes(1);
    const err = next.mock.calls[0][0];
    expect(err.status).toBe(400);
    expect(err.isOperational).toBe(true);
    expect(err.message).toBe("nombre requerido");
  });

  it("valida req.query cuando se pasa source='query'", () => {
    const querySchema = z.object({ lat: z.coerce.number() });
    const req = { query: { lat: "4.5" } };
    const next = jest.fn();
    validate(querySchema, "query")(req, {}, next);
    expect(next).toHaveBeenCalledWith();
    expect(req.query).toEqual({ lat: 4.5 });
  });
});
