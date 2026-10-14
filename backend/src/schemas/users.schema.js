const { z } = require("zod");

const actualizarUserSchema = z.object({
  nombre: z.string({ message: "nombre debe ser texto" }).min(1, "nombre no puede estar vacío").optional(),
  telefono: z.string({ message: "telefono debe ser texto" }).optional(),
  ciudad: z.string({ message: "ciudad debe ser texto" }).nullable().optional(),
  direccionReferencia: z
    .string({ message: "direccionReferencia debe ser texto" })
    .nullable()
    .optional(),
  fotoUrl: z.string({ message: "fotoUrl debe ser texto" }).optional(),
  fcmToken: z.string({ message: "fcmToken debe ser texto" }).nullable().optional(),
  notifCoincidencias: z.boolean({ message: "notifCoincidencias debe ser verdadero/falso" }).optional(),
  notifReportesCercanos: z.boolean({ message: "notifReportesCercanos debe ser verdadero/falso" }).optional(),
});

module.exports = { actualizarUserSchema };
