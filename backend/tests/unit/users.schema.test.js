const { actualizarUserSchema } = require("../../src/schemas/users.schema");

describe("actualizarUserSchema: teléfono", () => {
  it.each(["3001234567", "300 123 4567", "+57 300-123-4567", "(602) 8201234"])("acepta %s", (telefono) => {
    expect(actualizarUserSchema.safeParse({ telefono }).success).toBe(true);
  });

  it.each(["hola", "123", "300abc4567", "++573001234567", ""])("rechaza %p", (telefono) => {
    expect(actualizarUserSchema.safeParse({ telefono }).success).toBe(false);
  });
});
