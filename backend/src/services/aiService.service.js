const logger = require("../utils/logger");
const AppError = require("../utils/AppError");

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8001";
// Generoso a propósito: en Cloud Run el ai-service puede estar "frío" y tarda
// en arrancar y cargar el modelo la primera vez.
const VALIDACION_TIMEOUT_MS = Number(process.env.AI_VALIDACION_TIMEOUT_MS) || 30000;

function headersInternos() {
  return {
    "Content-Type": "application/json",
    "X-Internal-Api-Key": process.env.INTERNAL_API_KEY || "",
  };
}

function dispararGeneracionEmbedding(reporteId, fotoUrl) {
  fetch(`${AI_SERVICE_URL}/embeddings/generate`, {
    method: "POST",
    headers: headersInternos(),
    body: JSON.stringify({ reporteId, fotoUrl }),
  })
    .then((response) => {
      if (!response.ok) {
        logger.error(`ai-service: respondió ${response.status} para el reporte ${reporteId}`);
      }
    })
    .catch((err) => {
      logger.error(`ai-service: no se pudo generar el embedding del reporte ${reporteId}: ${err.message}`);
    });
}

/**
 * Le pregunta al ai-service si la foto muestra un perro o un gato.
 * Devuelve `{ esMascota, especieDetectada }`, `{ imagenInvalida: true }` si
 * el archivo no es una imagen, o `null` si no se pudo consultar (ai-service
 * caído, timeout, clave interna mal configurada).
 */
async function detectarMascota(fotoUrl) {
  try {
    const response = await fetch(`${AI_SERVICE_URL}/imagenes/validar`, {
      method: "POST",
      headers: headersInternos(),
      body: JSON.stringify({ fotoUrl }),
      signal: AbortSignal.timeout(VALIDACION_TIMEOUT_MS),
    });
    if (response.status === 422) return { imagenInvalida: true };
    if (!response.ok) {
      logger.warn(`ai-service: /imagenes/validar respondió ${response.status}; se omite la validación`);
      return null;
    }
    return await response.json();
  } catch (err) {
    logger.warn(`ai-service: no se pudo validar la foto (${err.message}); se omite la validación`);
    return null;
  }
}

/**
 * Rechaza (AppError 422) una foto que no muestra un perro o un gato, o cuya
 * especie no coincide con la elegida salvo que el usuario ya lo haya
 * confirmado (`aceptarEspecieDistinta`). Si el ai-service no responde no
 * bloquea al usuario: el reporte se publica igual, como antes de existir
 * esta validación (y queda en el log).
 */
async function validarFotoDeMascota(fotoUrl, especie, { aceptarEspecieDistinta = false } = {}) {
  const resultado = await detectarMascota(fotoUrl);
  if (!resultado) return;

  if (resultado.imagenInvalida) {
    throw new AppError(422, "No se pudo leer la foto. Intenta con otra imagen.", "foto_invalida");
  }
  if (!resultado.esMascota) {
    throw new AppError(
      422,
      "La foto no parece mostrar un perro o un gato. Usa una foto donde se vea bien al animal.",
      "foto_sin_mascota"
    );
  }
  const detectada = resultado.especieDetectada;
  if (detectada && especie && detectada !== especie && !aceptarEspecieDistinta) {
    throw new AppError(
      422,
      `La foto parece de un ${detectada.toLowerCase()}, pero elegiste ${especie}.`,
      "especie_distinta"
    );
  }
}

module.exports = { dispararGeneracionEmbedding, detectarMascota, validarFotoDeMascota };
