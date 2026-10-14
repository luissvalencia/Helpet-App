const logger = require("../utils/logger");

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8001";

function dispararGeneracionEmbedding(reporteId, fotoUrl) {
  fetch(`${AI_SERVICE_URL}/embeddings/generate`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Internal-Api-Key": process.env.INTERNAL_API_KEY || "",
    },
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

module.exports = { dispararGeneracionEmbedding };
