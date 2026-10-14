const { z } = require("zod");
const { mascotaSchema } = require("./common.schema");

const tipoSchema = z.enum(["perdida", "encontrada"], {
  message: "tipo debe ser 'perdida' o 'encontrada'",
});

const ubicacionSchema = z.object({
  lat: z.number({ message: "ubicacion.lat debe ser numérico" }),
  lng: z.number({ message: "ubicacion.lng debe ser numérico" }),
  direccionTexto: z.string({ message: "ubicacion.direccionTexto debe ser texto" }).optional(),
});

const crearReporteSchema = z.object({
  tipo: tipoSchema,
  mascota: mascotaSchema,
  fotoUrl: z.string({ message: "fotoUrl es requerido" }).min(1, "fotoUrl es requerido"),
  ubicacion: ubicacionSchema,
  mascotaId: z.string({ message: "mascotaId debe ser texto" }).optional(),
});

const actualizarReporteSchema = z
  .object({
    mascota: mascotaSchema.optional(),
    fotoUrl: z.string({ message: "fotoUrl debe ser texto" }).min(1, "fotoUrl no puede estar vacío").optional(),
    ubicacion: ubicacionSchema.optional(),
  })
  .partial();

const listarCercanosQuerySchema = z.object({
  lat: z.coerce.number({ message: "lat es requerido y debe ser numérico" }),
  lng: z.coerce.number({ message: "lng es requerido y debe ser numérico" }),
  radioKm: z.coerce.number({ message: "radioKm debe ser numérico" }).optional().default(10),
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
