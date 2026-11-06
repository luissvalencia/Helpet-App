const { z } = require("zod");
const { fotoUrlSchema, textoRequerido } = require("./common.schema");

// Mismo criterio que la app (mobile/lib/core/utils/validadores.dart): se
// ignoran espacios, guiones, puntos y paréntesis; debe quedar un número de 7
// a 15 dígitos, con "+" opcional al inicio. Es el medio de contacto que se
// revela al confirmar una coincidencia, así que no puede ser texto cualquiera.
const telefonoSchema = z
  .string({ message: "telefono debe ser texto" })
  .trim()
  .refine((t) => /^\+?\d{7,15}$/.test(t.replace(/[\s\-().]/g, "")), "telefono no es un número válido");

function textoNullable(campo, max) {
  return z
    .string({ message: `${campo} debe ser texto` })
    .trim()
    .max(max, `${campo} admite máximo ${max} caracteres`)
    .nullable()
    .optional();
}

const actualizarUserSchema = z.object({
  nombre: textoRequerido("nombre", 80).optional(),
  telefono: telefonoSchema.optional(),
  ciudad: textoNullable("ciudad", 80),
  direccionReferencia: textoNullable("direccionReferencia", 150),
  fotoUrl: fotoUrlSchema.optional(),
  fcmToken: z.string({ message: "fcmToken debe ser texto" }).max(4096).nullable().optional(),
  notifCoincidencias: z.boolean({ message: "notifCoincidencias debe ser verdadero/falso" }).optional(),
  notifReportesCercanos: z.boolean({ message: "notifReportesCercanos debe ser verdadero/falso" }).optional(),
});

module.exports = { actualizarUserSchema, telefonoSchema };
