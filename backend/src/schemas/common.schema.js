const { z } = require("zod");

const especieSchema = z.enum(["Perro", "Gato"], {
  message: "especie debe ser 'Perro' o 'Gato'",
});

// Texto libre: se recorta y se limita el largo, para que un campo con solo
// espacios no cuente como "lleno" y nadie guarde páginas enteras de texto.
function textoRequerido(campo, max) {
  return z
    .string({ message: `${campo} es requerido` })
    .trim()
    .min(1, `${campo} es requerido`)
    .max(max, `${campo} admite máximo ${max} caracteres`);
}

function textoOpcional(campo, max) {
  return z
    .string({ message: `${campo} debe ser texto` })
    .trim()
    .max(max, `${campo} admite máximo ${max} caracteres`)
    .optional();
}

const mascotaSchema = z.object({
  nombre: textoRequerido("mascota.nombre", 50),
  especie: especieSchema,
  raza: textoOpcional("mascota.raza", 60),
  color: textoOpcional("mascota.color", 60),
  descripcion: textoOpcional("mascota.descripcion", 500),
});

// Solo URLs de descarga del bucket de Firebase Storage de Helpet: el
// ai-service descarga esta URL, así que aceptar cualquiera permitiría
// hacerlo pedir recursos arbitrarios (SSRF) o publicar fotos externas.
const STORAGE_BUCKET = process.env.FIREBASE_STORAGE_BUCKET || "helpet-app-503fd.firebasestorage.app";
const PREFIJO_STORAGE = `https://firebasestorage.googleapis.com/v0/b/${STORAGE_BUCKET}/o/`;

const fotoUrlSchema = z
  .string({ message: "fotoUrl debe ser texto" })
  .refine((url) => url.startsWith(PREFIJO_STORAGE), "fotoUrl debe ser una foto subida desde la app");

module.exports = { especieSchema, mascotaSchema, fotoUrlSchema, textoRequerido, textoOpcional, PREFIJO_STORAGE };
