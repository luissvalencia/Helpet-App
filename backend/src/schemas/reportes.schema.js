const { z } = require("zod");
const { mascotaSchema, fotoUrlSchema, textoOpcional } = require("./common.schema");

const tipoSchema = z.enum(["perdida", "encontrada"], {
  message: "tipo debe ser 'perdida' o 'encontrada'",
});

const ubicacionSchema = z.object({
  lat: z
    .number({ message: "ubicacion.lat debe ser numérico" })
    .min(-90, "ubicacion.lat fuera de rango")
    .max(90, "ubicacion.lat fuera de rango"),
  lng: z
    .number({ message: "ubicacion.lng debe ser numérico" })
    .min(-180, "ubicacion.lng fuera de rango")
    .max(180, "ubicacion.lng fuera de rango"),
  direccionTexto: textoOpcional("ubicacion.direccionTexto", 200),
});

// Si la foto parece de otra especie que la elegida, el backend responde 422
// con codigo "especie_distinta"; la app pregunta y, si el usuario confirma
// que la especie elegida es la correcta, reenvía con esto en true.
const confirmarEspecieSchema = z.boolean({ message: "confirmarEspecie debe ser verdadero/falso" }).optional();

const crearReporteSchema = z.object({
  tipo: tipoSchema,
  mascota: mascotaSchema,
  fotoUrl: fotoUrlSchema,
  ubicacion: ubicacionSchema,
  mascotaId: z.string({ message: "mascotaId debe ser texto" }).optional(),
  confirmarEspecie: confirmarEspecieSchema,
});

const actualizarReporteSchema = z
  .object({
    mascota: mascotaSchema.optional(),
    fotoUrl: fotoUrlSchema.optional(),
    ubicacion: ubicacionSchema.optional(),
    confirmarEspecie: confirmarEspecieSchema,
  })
  .partial();

const listarCercanosQuerySchema = z.object({
  lat: z.coerce.number({ message: "lat es requerido y debe ser numérico" }).min(-90).max(90),
  lng: z.coerce.number({ message: "lng es requerido y debe ser numérico" }).min(-180).max(180),
  radioKm: z.coerce
    .number({ message: "radioKm debe ser numérico" })
    .positive("radioKm debe ser mayor que 0")
    .max(500, "radioKm admite máximo 500")
    .optional()
    .default(10),
});

const listarPropiosQuerySchema = z.object({
  tipo: tipoSchema.optional(),
});

module.exports = {
  crearReporteSchema,
  actualizarReporteSchema,
  listarCercanosQuerySchema,
  listarPropiosQuerySchema,
};
