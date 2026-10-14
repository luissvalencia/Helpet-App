const logger = require("../utils/logger");

function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  const isOperational = err.isOperational === true;

  if (isOperational) {
    logger.warn(err.message, { status, path: req.originalUrl });
  } else {
    logger.error(err.message, { stack: err.stack, path: req.originalUrl });
  }

  const exponerDetalle = isOperational || process.env.NODE_ENV !== "production";
  const message = exponerDetalle ? err.message || "Error interno del servidor" : "Error interno del servidor";

  res.status(status).json({ error: message });
}

module.exports = errorHandler;
