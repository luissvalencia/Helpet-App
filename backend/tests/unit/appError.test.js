const AppError = require("../../src/utils/AppError");

describe("AppError", () => {
  it("guarda status, mensaje y se marca como operacional", () => {
    const err = new AppError(404, "no encontrado");
    expect(err).toBeInstanceOf(Error);
    expect(err.status).toBe(404);
    expect(err.message).toBe("no encontrado");
    expect(err.isOperational).toBe(true);
  });
});
