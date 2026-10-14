const { z } = require("zod");

const especieSchema = z.enum(["Perro", "Gato"], {
  message: "especie debe ser 'Perro' o 'Gato'",
});

const mascotaSchema = z.object({
  nombre: z.string({ message: "mascota.nombre es requerido" }).min(1, "mascota.nombre es requerido"),
  especie: especieSchema,
  raza: z.string({ message: "mascota.raza debe ser texto" }).optional(),
  color: z.string({ message: "mascota.color debe ser texto" }).optional(),
  descripcion: z.string({ message: "mascota.descripcion debe ser texto" }).optional(),
});

module.exports = { especieSchema, mascotaSchema };
